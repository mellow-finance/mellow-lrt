// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IWSteth} from "../../../src/interfaces/external/lido/IWSteth.sol";

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

contract sUSDeOracle {
    uint256 private constant Q96 = 2 ** 96;

    function priceX96() external view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            0x7C45F7ff7dDeaC1af333E469f4B99bbd75Ee5495
        );
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 wstethPriceX96 = Math.mulDiv(sqrtPriceX96, sqrtPriceX96, Q96);
        wstethPriceX96 = Math.mulDiv(Q96, Q96, wstethPriceX96);

        return
            IWSteth(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0)
                .getStETHByWstETH(wstethPriceX96);
    }
}
