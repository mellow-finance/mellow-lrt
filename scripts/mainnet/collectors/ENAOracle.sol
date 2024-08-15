// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

contract ENAOracle {
    function priceX96() external view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(
            0xc3Db44ADC1fCdFd5671f555236eae49f4A8EEa18
        ).slot0();
        return Math.mulDiv(sqrtPriceX96, sqrtPriceX96, 2 ** 96);
    }
}
