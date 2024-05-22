// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";

contract ConstantAggregatorV3 is IAggregatorV3 {
    uint8 public constant decimals = 18;
    string public constant description = "ConstantAggregatorV3";
    uint256 public constant version = 1;
    int256 public immutable answer;

    constructor(int256 _answer) {
        answer = _answer;
    }

    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer_,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, answer, block.timestamp, block.timestamp, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer_,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, answer, block.timestamp, block.timestamp, 0);
    }
}
