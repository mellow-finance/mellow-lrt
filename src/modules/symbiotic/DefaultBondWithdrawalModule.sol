// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/symbiotic/IDefaultBondWithdrawalModule.sol";

contract DefaultBondWithdrawalModule is IDefaultBondWithdrawalModule {
    function withdraw(address bond, uint256 amount) external {
        uint256 balance = IDefaultBond(bond).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount == 0) return;
        IDefaultBond(bond).withdraw(address(this), amount);
    }
}
