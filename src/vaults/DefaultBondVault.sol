// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/vaults/IDefaultBondVault.sol";

import "../validators/Validator.sol";

import "./Subvault.sol";

contract DefaultBondVault is IDefaultBondVault, Subvault {
    using SafeERC20 for IERC20;

    mapping(address => address) public bonds;

    constructor(IRootVault rootVault_) Subvault(rootVault_) {}

    function enableBond(address token, address bond) external onlyAdmin {
        bonds[token] = bond;
    }

    function disableBond(address token, address bond) external onlyAdmin {
        _pullBond(bond, type(uint256).max);
        delete bonds[token];
    }

    function _pullBond(address bond, uint256 amount) private returns (uint256) {
        if (bond == address(0)) return 0;
        uint256 balance = IERC20(bond).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount > 0)
            IDefaultBond(bond).withdraw(rootVault.subvaultAt(0), amount);
        return amount;
    }

    function addToken(address token) external onlyRootVault {}

    function removeToken(address token) external onlyRootVault {
        _pullBond(bonds[token], type(uint256).max);
        delete bonds[token];
    }

    function push(
        uint256[] memory tokenAmounts
    ) external atLeastOperator returns (uint256[] memory actualTokenAmounts) {
        address[] memory tokens = rootVault.tokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            address bond = bonds[tokens[i]];
            if (bond == address(0)) continue;
            IERC20(tokens[i]).safeIncreaseAllowance(
                address(bond),
                tokenAmounts[i]
            );
            actualTokenAmounts[i] = IDefaultBond(bond).deposit(
                address(this),
                tokenAmounts[i]
            );
        }
    }

    function pull(
        address to,
        uint256[] memory amounts
    ) external atLeastOperator returns (uint256[] memory actualTokenAmounts) {
        if (to != rootVault.subvaultAt(0)) revert InvalidSubvault();
        address[] memory tokens_ = rootVault.tokens();
        if (tokens_.length != amounts.length) revert InvalidLength();
        actualTokenAmounts = amounts;
        for (uint256 i = 0; i < tokens_.length; i++) {
            actualTokenAmounts[i] = _pullBond(bonds[tokens_[i]], amounts[i]);
        }
    }

    function tvl() external view returns (uint256[] memory amounts) {
        address[] memory tokens_ = rootVault.tokens();
        amounts = new uint256[](tokens_.length);
        for (uint256 i = 0; i < tokens_.length; i++) {
            address bond = bonds[tokens_[i]];
            if (bond == address(0)) continue;
            amounts[i] = IERC20(bond).balanceOf(address(this));
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, Subvault) returns (bool) {
        return
            interfaceId == type(IDefaultBondVault).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
