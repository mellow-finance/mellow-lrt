// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "./StakingModule.sol";

interface IMutableStakingModule {
    /*
        Logic:
        1. get available keys
        2. get depositable ether
        3. calculate available amount of ETH for staking
        4. revert if zero
    */
    function getAmountForStake(
        bytes calldata data
    ) external view returns (uint256 amount); // revert if not in the right state
}

contract MutableStakingModule is IMutableStakingModule {
    function getAmountForStake(
        bytes calldata data
    ) external pure returns (uint256) {
        // return 0;
    }
}
