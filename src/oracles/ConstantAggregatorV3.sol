// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/external/chainlink/IAggregatorV3.sol";

contract ConstantAggregatorV3 is IAggregatorV3 {
    uint8 public constant decimals = 18;
    int256 public immutable answer;

    constructor(int256 _answer) {
        answer = _answer;
    }

    function latestRoundData()
        public
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, answer, block.timestamp, block.timestamp, 0);
    }
}
