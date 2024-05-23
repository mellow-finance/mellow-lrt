// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/external/chainlink/IAggregatorV3.sol";
import "../interfaces/external/lido/IWSteth.sol";

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
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return latestRoundData();
    }

    function latestRoundData()
        public
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, getAnswer(), block.timestamp, block.timestamp, 0);
    }
}
