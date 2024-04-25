// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/external/symbiotic/IDefaultBond.sol";

import "../../../interfaces/modules/IMutableModule.sol";

contract DefaultBondWithdrawalModule is IMutableModule {
    using SafeERC20 for IERC20;

    function withdraw(address bond, uint256 amount) external {
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
