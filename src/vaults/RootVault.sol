// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/vaults/ISubvault.sol";
import "../interfaces/vaults/IERC20Vault.sol";

import "../libraries/external/FullMath.sol";

import "../oracles/Oracle.sol";
import "../oracles/RatiosOracle.sol";

import "../utils/DefaultAccessControl.sol";

import "./ERC20Vault.sol";

contract RootVault is DefaultAccessControl, ERC20 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    error AlreadyInitialized();
    error InvalidLength();
    error InvalidSubvault();
    error InvalidAddress();
    error InvalidValue();

    // immutable params

    uint256 public constant D9 = 1e9;
    uint256 public constant Q96 = 2 ** 96;

    Oracle public immutable oracle;
    RatiosOracle public immutable ratiosOracle;
    address public immutable validator;

    address[] private _subvaults;
    EnumerableSet.AddressSet private _subvaultsSet;

    address[] private _tokens;

    // mutable params
    uint256 public withdrawalFeeD9;

    constructor(
        address admin,
        Oracle oracle_,
        RatiosOracle ratiosOracle_,
        string memory name_,
        string memory symbol_
    ) DefaultAccessControl(admin) ERC20(name_, symbol_) {
        oracle = oracle_;
        ratiosOracle = ratiosOracle_;
    }

    function initialize(
        address[] memory subvaults_,
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256 initialTotalSupply_
    ) external {
        _requireAdmin();
        if (_subvaults.length != 0) revert AlreadyInitialized();
        if (subvaults_.length == 0) revert InvalidLength();
        for (uint256 i = 0; i < subvaults_.length; i++) {
            if (subvaults_[i] == address(0)) revert AddressZero();
            if (address(ISubvault(subvaults_[i]).rootVault()) != address(this))
                revert InvalidSubvault();
        }
        if (
            !ISubvault(subvaults_[0]).supportsInterface(
                type(IERC20Vault).interfaceId
            )
        ) revert InvalidSubvault();

        for (uint256 i = 1; i < tokens_.length; i++) {
            if (tokens_[i] <= tokens_[i - 1]) revert InvalidAddress();
            IERC20(_tokens[i]).safeTransferFrom(
                msg.sender,
                subvaults_[0],
                amounts_[i]
            );
        }

        for (uint256 i = 0; i < subvaults_.length; i++) {
            _subvaultsSet.add(subvaults_[i]);
        }

        if (_subvaultsSet.length() != subvaults_.length) revert InvalidLength();
        if (initialTotalSupply_ == 0) revert InvalidValue();
        _subvaults = subvaults_;
        _tokens = tokens_;
        _mint(address(this), initialTotalSupply_);
    }

    function subvaultCount() external view returns (uint256) {
        return _subvaults.length;
    }

    function subvaultAt(uint256 index) external view returns (address) {
        return _subvaults[index];
    }

    function hasSubvault(address vault) external view returns (bool) {
        return _subvaultsSet.contains(vault);
    }

    function deposit(
        uint256[] memory amounts,
        uint256 minLpAmount
    ) external returns (uint256 lpAmount, uint256[] memory actualTokenAmounts) {
        address[] memory tokens_ = _tokens;
        if (tokens_.length != amounts.length) revert InvalidLength();
        address erc20Vault = _subvaults[0];
        actualTokenAmounts = new uint256[](tokens_.length);

        uint256[] memory totalTvl = tvl();

        uint256[] memory taregetRatiosX96 = ratiosOracle.getTargetRatiosX96(
            address(this)
        );

        uint256 ratioX96 = type(uint256).max;
        for (uint256 i = 0; i < tokens_.length; i++) {
            uint256 currentRatioX96 = FullMath.mulDiv(
                Q96,
                amounts[i],
                taregetRatiosX96[i]
            );
            if (currentRatioX96 < ratioX96) {
                ratioX96 = currentRatioX96;
            }
        }

        uint256 totalValue = 0;
        uint256 depositValue = 0;

        for (uint256 i = 0; i < tokens_.length; i++) {
            actualTokenAmounts[i] = FullMath.mulDiv(
                taregetRatiosX96[i],
                ratioX96,
                Q96
            );
            IERC20(tokens_[i]).safeTransferFrom(
                msg.sender,
                erc20Vault,
                actualTokenAmounts[i]
            );
            uint256 priceX96 = oracle.priceX96(tokens_[i]);
            totalValue += FullMath.mulDiv(totalTvl[i], priceX96, Q96);
            depositValue = FullMath.mulDiv(
                actualTokenAmounts[i],
                priceX96,
                Q96
            );
        }

        lpAmount = FullMath.mulDiv(depositValue, totalSupply(), totalValue);
        if (lpAmount < minLpAmount) revert("RootVault: insufficient LP amount");

        _mint(msg.sender, lpAmount);
    }

    function withdraw(
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    )
        external
        returns (uint256 actualLpAmount, uint256[] memory actualTokenAmounts)
    {
        address[] memory tokens_ = _tokens;
        if (tokens_.length != minTokenAmounts.length) revert InvalidLength();
        address erc20Vault = _subvaults[0];
        actualTokenAmounts = new uint256[](tokens_.length);
        uint256[] memory erc20Tvl = ISubvault(erc20Vault).tvl();
        uint256[] memory totalTvl = tvl();

        {
            uint256 balance = balanceOf(msg.sender);
            if (balance < lpAmount) lpAmount = balance;
        }

        uint256 denominator = 0;
        uint256 totalValue = 0;
        uint256[] memory pricesX96 = new uint256[](tokens_.length);
        uint256[] memory targetRatiosX96 = ratiosOracle.getTargetRatiosX96(
            address(this)
        );
        for (uint256 i = 0; i < tokens_.length; i++) {
            uint256 priceX96 = oracle.priceX96(tokens_[i]);
            if (totalTvl[i] > 0)
                totalValue += FullMath.mulDiv(totalTvl[i], priceX96, Q96);
            if (targetRatiosX96[i] > 0)
                denominator += FullMath.mulDiv(
                    targetRatiosX96[i],
                    priceX96,
                    Q96
                );
            pricesX96[i] = priceX96;
        }
        uint256 totalSupply_ = totalSupply();
        uint256 withdrawValue = FullMath.mulDiv(
            totalValue,
            lpAmount,
            totalSupply_
        );
        withdrawValue = FullMath.mulDiv(
            withdrawValue,
            D9 - withdrawalFeeD9,
            D9
        );
        uint256 ratioX96 = FullMath.mulDiv(withdrawValue, Q96, denominator);
        for (uint256 i = 0; i < tokens_.length; i++) {
            uint256 allowedRatioX96 = FullMath.mulDiv(
                erc20Tvl[i],
                Q96,
                targetRatiosX96[i]
            );
            if (allowedRatioX96 < ratioX96) {
                ratioX96 = allowedRatioX96;
            }
        }

        withdrawValue = 0;
        for (uint256 i = 0; i < tokens_.length; i++) {
            actualTokenAmounts[i] = FullMath.mulDiv(
                ratioX96,
                targetRatiosX96[i],
                Q96
            );
            withdrawValue += FullMath.mulDiv(
                actualTokenAmounts[i],
                pricesX96[i],
                Q96
            );
            if (actualTokenAmounts[i] < minTokenAmounts[i])
                revert("RootVault: insufficient token amount");
        }

        actualLpAmount = FullMath.mulDivRoundingUp(
            withdrawValue,
            totalSupply_,
            totalValue
        );

        _burn(msg.sender, actualLpAmount);
        IERC20Vault(erc20Vault).pull(address(this), actualTokenAmounts);
        for (uint256 i = 0; i < tokens_.length; i++) {
            IERC20(tokens_[i]).safeTransfer(msg.sender, actualTokenAmounts[i]);
        }
    }

    function tvl() public view returns (uint256[] memory amounts) {
        address[] memory subvaults_ = _subvaults;
        amounts = ISubvault(subvaults_[0]).tvl();
        for (uint256 i = 1; i < subvaults_.length; i++) {
            uint256[] memory subvaultTvl = ISubvault(subvaults_[i]).tvl();
            for (uint256 j = 0; j < amounts.length; j++) {
                amounts[j] += subvaultTvl[j];
            }
        }
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function addToken(address token) external {
        _requireAdmin();
        _tokens.push(token);
        uint256 n = _tokens.length;
        for (uint256 i = 1; i < n; i++) {
            address currentToken = _tokens[n - 1 - i];
            if (currentToken == token)
                revert("RootVault: token already exists");
            if (currentToken < token) break;
            _tokens[n - 1 - i] = token;
            _tokens[n - i] = currentToken;
        }

        address[] memory subvaults_ = _subvaults;
        for (uint256 i = 0; i < subvaults_.length; i++) {
            ISubvault(subvaults_[i]).addToken(token);
        }
    }

    function removeToken(address token) external {
        _requireAdmin();
        uint256 n = _tokens.length;
        uint256 j = n;
        for (uint256 i = 0; i < n; i++) {
            if (_tokens[i] == token) j = i;
            if (j < i) _tokens[i - 1] = _tokens[i];
        }
        if (j == n) revert("RootVault: token not found");
        _tokens.pop();

        address[] memory subvaults_ = _subvaults;
        for (uint256 i = 0; i < subvaults_.length; i++) {
            ISubvault(subvaults_[i]).removeToken(token);
        }
    }
}
