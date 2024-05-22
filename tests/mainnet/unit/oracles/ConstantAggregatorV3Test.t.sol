// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructorConstantAggregatorV3() external {
        ConstantAggregatorV3 oracle = new ConstantAggregatorV3(0);
        assertEq(oracle.decimals(), 18);
        assertEq(oracle.description(), "ConstantAggregatorV3");
        assertEq(oracle.version(), 1);
        assertEq(oracle.answer(), 0);
    }

    function testGetRoundData() external {
        ConstantAggregatorV3 oracle = new ConstantAggregatorV3(0);
        (, int256 price, , , ) = oracle.getRoundData(0);
        assertEq(price, 0);
        oracle = new ConstantAggregatorV3(1);
        assertEq(oracle.decimals(), 18);
        (, price, , , ) = oracle.getRoundData(0);
        assertEq(price, 1);
        (, price, , , ) = oracle.getRoundData(type(uint80).max);
        assertEq(price, 1);
    }

    function testLatestRoundData() external {
        ConstantAggregatorV3 oracle = new ConstantAggregatorV3(0);
        (, int256 price, , , ) = oracle.latestRoundData();
        assertEq(price, 0);
        oracle = new ConstantAggregatorV3(1);
        assertEq(oracle.decimals(), 18);
        (, price, , , ) = oracle.latestRoundData();
        assertEq(price, 1);
    }
}
