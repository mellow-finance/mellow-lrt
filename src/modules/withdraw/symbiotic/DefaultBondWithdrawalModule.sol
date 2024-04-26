// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../../interfaces/external/symbiotic/IDefaultBond.sol";
import "../../../interfaces/modules/IMutableModule.sol";

contract DefaultBondWithdrawalModule is IMutableModule {
    function withdraw(address bond, uint256 amount) external {
        uint256 balance = IDefaultBond(bond).balanceOf(address(this));
        if (balance < amount) amount = balance;
        if (amount == 0) return;
        IDefaultBond(bond).withdraw(address(this), amount);
    }

    function selectors()
        external
        pure
        override
        returns (bytes4[] memory selectors_)
    {
        selectors_ = new bytes4[](1);
        selectors_[0] = this.withdraw.selector;
    }
}
