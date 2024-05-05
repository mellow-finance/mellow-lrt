// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";

contract AggregatorV3WethMock is IAggregatorV3 {
    function testMock() external {}

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function description() external pure returns (string memory) {
        return "WSTETH / USD";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        pure
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {}

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 x,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 y
        )
    {
        updatedAt = block.timestamp;
        startedAt = block.timestamp;
        answer = 1e18;
        x = 0;
        y = 0;
    }
}
