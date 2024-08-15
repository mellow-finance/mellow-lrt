// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAggregatorV3} from "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";

contract wBTCOracle {
    function priceX96() external view returns (uint256) {
        (, int256 price, , , ) = IAggregatorV3(
            0xdeb288F737066589598e9214E782fa5A8eD689e8
        ).latestRoundData();
        return Math.mulDiv(uint256(price), 2 ** 96, 1e8);
    }
}
