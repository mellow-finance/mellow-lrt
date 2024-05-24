// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../src/libraries/external/FullMath.sol";

contract FullMathMock {
    function test() external pure {}

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256) {
        return FullMath.mulDiv(a, b, denominator);
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256) {
        return FullMath.mulDivRoundingUp(a, b, denominator);
    }
}
