// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IAggregatorV3} from "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";

contract tBTCOracle {
    function priceX96() external view returns (uint256) {
        (, int256 tbtcUsd8, , , ) = IAggregatorV3(
            0x8350b7De6a6a2C1368E7D4Bd968190e13E354297
        ).latestRoundData();
        (, int256 ethUsd8, , , ) = IAggregatorV3(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ).latestRoundData();

        return Math.mulDiv(uint256(tbtcUsd8), 2 ** 96, uint256(ethUsd8));
    }
}
