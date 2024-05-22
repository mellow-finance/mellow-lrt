// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../../interfaces/external/chainlink/IAggregatorV3.sol";
import "../../../interfaces/external/lido/IWSteth.sol";

contract WStethRatiosAggregatorV3 is IAggregatorV3 {
    uint8 public constant decimals = 18;
    string public constant description = "WStethRatiosAggregatorV3";
    uint256 public constant version = 1;
    address public immutable wsteth;

    constructor(address wsteth_) {
        wsteth = wsteth_;
    }

    function getAnswer() public view returns (int256) {
        return int256(IWSteth(wsteth).getStETHByWstETH(10 ** decimals));
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
        return (0, getAnswer(), block.timestamp, block.timestamp, 0);
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
        return (0, getAnswer(), block.timestamp, block.timestamp, 0);
    }
}
