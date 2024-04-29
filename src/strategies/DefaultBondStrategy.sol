// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/utils/IDepositCallback.sol";

import "../interfaces/modules/erc20/IERC20TvlModule.sol";
import "../interfaces/modules/symbiotic/IDefaultBondDepositModule.sol";
import "../interfaces/modules/symbiotic/IDefaultBondWithdrawalModule.sol";

import "../libraries/external/FullMath.sol";

import "../utils/DefaultAccessControl.sol";

contract DefaultBondStrategy is IDepositCallback, DefaultAccessControl {
    struct Data {
        address bond;
        uint256 ratioX96;
    }

    uint256 public constant Q96 = 2 ** 96;

    IVault public immutable vault;

    mapping(address => bytes) public tokenToData;

    IERC20TvlModule public immutable erc20TvlModule;
    IDefaultBondDepositModule public immutable depositModule;
    IDefaultBondWithdrawalModule public immutable withdrawalModule;

    constructor(
        address admin,
        IVault vault_,
        IERC20TvlModule erc20TvlModule_,
        IDefaultBondDepositModule depositModule_,
        IDefaultBondWithdrawalModule withdrawalModule_
    ) DefaultAccessControl(admin) {
        vault = vault_;
        erc20TvlModule = erc20TvlModule_;
        depositModule = depositModule_;
        withdrawalModule = withdrawalModule_;
    }

    function setData(address token, Data[] memory data) external {
        _requireAdmin();
        if (token == address(0)) revert AddressZero();
        uint256 cumulativeRatio = 0;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].bond == address(0)) revert AddressZero();
            cumulativeRatio += data[i].ratioX96;
        }
        if (cumulativeRatio != Q96)
            revert("DefaultBondStrategy: cumulative ratio is not equal to 1");
        tokenToData[token] = abi.encode(data);
    }

    function _deposit() private {
        (address[] memory tokens, uint256[] memory amounts) = erc20TvlModule
            .tvl(address(vault), new bytes(0));
        for (uint256 i = 0; i < tokens.length; i++) {
            bytes memory data_ = tokenToData[tokens[i]];
            if (data_.length == 0) continue;
            Data[] memory data = abi.decode(data_, (Data[]));
            if (data.length == 0) continue;
            for (uint256 j = 0; j < data.length; j++) {
                uint256 amount = FullMath.mulDiv(
                    amounts[i],
                    data[j].ratioX96,
                    Q96
                );
                if (amount == 0) continue;
                vault.delegateCall(
                    address(depositModule),
                    abi.encodeWithSelector(
                        depositModule.deposit.selector,
                        data[j].bond,
                        amount
                    )
                );
            }
        }
    }

    function depositCallback() external {
        if (msg.sender != address(vault)) _requireAtLeastOperator();
        _deposit();
    }

    function processAll() external {
        _requireAtLeastOperator();
        _processWithdrawals(vault.withdrawers());
    }

    function processWithdrawals(address[] memory users) external {
        _requireAtLeastOperator();
        _processWithdrawals(users);
    }

    function _processWithdrawals(address[] memory users) private {
        if (users.length == 0) return;

        address[] memory tokens = vault.underlyingTokens();
        for (uint256 index = 0; index < tokens.length; index++) {
            bytes memory data_ = tokenToData[tokens[index]];
            if (data_.length == 0) continue;
            Data[] memory data = abi.decode(data_, (Data[]));
            for (uint256 i = 0; i < data.length; i++) {
                vault.delegateCall(
                    address(withdrawalModule),
                    abi.encodeWithSelector(
                        withdrawalModule.withdraw.selector,
                        data[i].bond,
                        IERC20(data[i].bond).balanceOf(address(vault))
                    )
                );
            }
        }

        vault.processWithdrawals(users);
        _deposit();
    }
}
