// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

interface IWithdrawalQueue {
    function unfinalizedStETH() external view returns (uint256);
}
