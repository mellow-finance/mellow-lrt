// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructorConstantAggregatorV3() external {
        WStethRatiosAggregatorV3 oracle = new WStethRatiosAggregatorV3(
            Constants.WSTETH
        );
        assertEq(oracle.decimals(), 18);
        assertEq(oracle.description(), "WStethRatiosAggregatorV3");
        assertEq(oracle.version(), 1);
        assertEq(oracle.wsteth(), Constants.WSTETH);
    }

    function testGetAnswer() external {
        WStethRatiosAggregatorV3 oracle = new WStethRatiosAggregatorV3(
            address(0)
        );
        vm.expectRevert();
        oracle.getAnswer();
        oracle = new WStethRatiosAggregatorV3(Constants.WSTETH);
        int256 price = oracle.getAnswer();
        assertTrue(price > 1 ether && price < 1.3 ether);
    }

    function testGetRoundData() external {
        WStethRatiosAggregatorV3 oracle = new WStethRatiosAggregatorV3(
            address(0)
        );
        vm.expectRevert();
        oracle.getRoundData(0);
        oracle = new WStethRatiosAggregatorV3(Constants.WSTETH);
        (, int256 price, , , ) = oracle.getRoundData(0);
        assertTrue(price > 1 ether && price < 1.3 ether);
        (, price, , , ) = oracle.getRoundData(type(uint80).max);
        assertTrue(price > 1 ether && price < 1.3 ether);
    }

    function testLatestRoundData() external {
        WStethRatiosAggregatorV3 oracle = new WStethRatiosAggregatorV3(
            address(0)
        );
        vm.expectRevert();
        oracle.latestRoundData();
        oracle = new WStethRatiosAggregatorV3(Constants.WSTETH);
        (, int256 price, , , ) = oracle.latestRoundData();
        assertTrue(price > 1 ether && price < 1.3 ether);
    }
}
