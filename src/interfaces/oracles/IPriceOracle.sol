// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPriceOracle {
    function priceX96(address token) external view returns (uint256 priceX96_);
}
