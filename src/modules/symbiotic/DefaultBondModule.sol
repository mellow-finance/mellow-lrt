// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../interfaces/modules/symbiotic/IDefaultBondModule.sol";
import "../DefaultModule.sol";

contract DefaultBondModule is IDefaultBondModule, DefaultModule {
    using SafeERC20 for IERC20;

    /// @inheritdoc IDefaultBondModule
    function deposit(
        address bond,
        uint256 amount
    ) external onlyDelegateCall returns (uint256) {
        if (amount == 0) return 0;
        IERC20(IBond(bond).asset()).safeIncreaseAllowance(bond, amount);
        emit DefaultBondModuleDeposit(bond, amount, block.timestamp);
        return IDefaultBond(bond).deposit(address(this), amount);
    }

    /// @inheritdoc IDefaultBondModule
    function withdraw(
        address bond,
        uint256 amount
    ) external onlyDelegateCall returns (uint256) {
        uint256 balance = IDefaultBond(bond).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount == 0) return 0;
        IDefaultBond(bond).withdraw(address(this), amount);
        emit DefaultBondModuleWithdraw(bond, amount);
        return amount;
    }
}
