// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface IWithdrawalQueue {
    function unfinalizedStETH() external view returns (uint256);
}
