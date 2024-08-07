// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

contract MellowRewards {
    function stake(uint256 amount) external {}

    function unstake(uint256 amount) external {}

    function claim(address token) external {}

    function distributeRewards(
        address token,
        uint256 amount,
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) external {}
}
