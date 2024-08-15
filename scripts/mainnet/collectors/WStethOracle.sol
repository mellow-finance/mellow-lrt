// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IWSteth} from "../../../src/interfaces/external/lido/IWSteth.sol";

contract WStethOracle {
    function priceX96() external view returns (uint256) {
        return
            IWSteth(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0)
                .getStETHByWstETH(2 ** 96);
    }
}
