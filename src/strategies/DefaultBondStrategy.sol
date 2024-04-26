// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/utils/IDepositCallback.sol";

import "../modules/tvl/erc20/ERC20TvlModule.sol";
import "../modules/deposit/symbiotic/DefaultBondDepositModule.sol";
import "../modules/withdraw/symbiotic/DefaultBondWithdrawalModule.sol";

import "../utils/DefaultAccessControl.sol";

contract DefaultBondStrategy is IDepositCallback, DefaultAccessControl {
    ERC20TvlModule public erc20TvlModule;
    DefaultBondDepositModule public depositModule;
    DefaultBondWithdrawalModule public withdrawalModule;

    address[] public supportedBonds;

    IVault public immutable vault;

    constructor(address admin, IVault vault_) DefaultAccessControl(admin) {
        vault = vault_;
    }

    function _deposit() private {
        // TODO: fix
        (address[] memory tokens, uint256[] memory amounts) = erc20TvlModule
            .tvl(address(vault), new bytes(0));
        address[] memory bonds = supportedBonds;
        for (uint256 i = 0; i < bonds.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                if (IDefaultBond(bonds[i]).asset() != tokens[j]) continue;
                vault.delegateCall(
                    address(depositModule),
                    abi.encodeWithSelector(
                        depositModule.deposit.selector,
                        bonds[i],
                        amounts[j]
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
        address[] memory bonds = supportedBonds;
        for (uint256 i = 0; i < bonds.length; i++) {
            vault.delegateCall(
                address(withdrawalModule),
                abi.encodeWithSelector(
                    withdrawalModule.withdraw.selector,
                    bonds[i],
                    IERC20(bonds[i]).balanceOf(address(vault))
                )
            );
        }
        vault.processWithdrawals(users);
        _deposit();
    }
}
