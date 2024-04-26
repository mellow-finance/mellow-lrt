// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/external/symbiotic/IDefaultBond.sol";

import "../../../interfaces/modules/IMutableModule.sol";

contract DefaultBondDepositModule is IMutableModule {
    using SafeERC20 for IERC20;

    function deposit(address bond, uint256 amount) external {
        if (amount == 0) return;
        IERC20(bond).safeIncreaseAllowance(address(this), amount);
        IDefaultBond(bond).deposit(address(this), amount);
    }

    function selectors()
        external
        pure
        override
        returns (bytes4[] memory selectors_)
    {
        selectors_ = new bytes4[](1);
        selectors_[0] = this.deposit.selector;
    }
}
