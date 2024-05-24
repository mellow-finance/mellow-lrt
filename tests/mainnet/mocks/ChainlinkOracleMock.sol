// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";

contract ChainlinkOracleMock is IAggregatorV3 {
    function testMock() external {}

    function decimals() external view returns (uint8) {}

    function description() external pure returns (string memory) {}

    function version() external view returns (uint256) {}

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
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {}
}
