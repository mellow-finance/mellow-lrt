// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/symbiotic/IDefaultBondModule.sol";
import "../DefaultModule.sol";

contract DefaultBondModule is IDefaultBondModule, DefaultModule {
    using SafeERC20 for IERC20;

    function deposit(address bond, uint256 amount) external onlyDelegateCall {
        if (amount == 0) return;
        IERC20(IBond(bond).asset()).safeIncreaseAllowance(bond, amount);
        IDefaultBond(bond).deposit(address(this), amount);
    }

    function withdraw(address bond, uint256 amount) external onlyDelegateCall {
        uint256 balance = IDefaultBond(bond).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount == 0) return;
        IDefaultBond(bond).withdraw(address(this), amount);
    }
}
