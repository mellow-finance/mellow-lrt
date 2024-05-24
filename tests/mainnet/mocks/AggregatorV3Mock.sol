// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";

contract AggregatorV3Mock is IAggregatorV3 {
    function testMock() external {}

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function description() external pure returns (string memory) {
        return "mock";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80 _roundId
    ) external pure returns (uint80, int256, uint256, uint256, uint80) {}

    uint80 public latestRoundId;
    uint80 public x;
    int256 public answer;
    uint256 public startedAt;
    uint256 public updatedAt;
    uint80 public y;

    function setData(
        uint80 x_,
        int256 answer_,
        uint256 startedAt_,
        uint256 updatedAt_,
        uint80 y_
    ) external {
        x = x_;
        answer = answer_;
        startedAt = startedAt_;
        updatedAt = updatedAt_;
        y = y_;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (x, answer, startedAt, updatedAt, y);
    }
}
