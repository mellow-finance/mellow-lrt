// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../external/symbiotic/IDefaultBond.sol";

interface IDefaultBondWithdrawalModule {
    function withdraw(address bond, uint256 amount) external;
}
