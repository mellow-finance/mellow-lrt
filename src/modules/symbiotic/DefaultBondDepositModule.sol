// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/symbiotic/IDefaultBondDepositModule.sol";

contract DefaultBondDepositModule is IDefaultBondDepositModule {
    using SafeERC20 for IERC20;

    function deposit(address bond, uint256 amount) external {
        if (amount == 0) return;
        IERC20(IBond(bond).asset()).safeIncreaseAllowance(bond, amount);
        IDefaultBond(bond).deposit(address(this), amount);
    }
}
