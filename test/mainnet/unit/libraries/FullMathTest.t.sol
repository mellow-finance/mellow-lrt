// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../Constants.sol";

contract Unit is Test {
    function check(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) public pure returns (uint256) {
        unchecked {
            uint256 prod0;
            uint256 prod1;
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            if (prod1 == 0) {
                if (denominator <= 0) return 1;
                return 0;
            }

            if (denominator <= prod1) return 2;
        }
        return 0;
    }

    uint256 public constant len = 15;
    uint256[len] public values = [
        0,
        1,
        type(uint8).max,
        type(uint128).max,
        type(uint224).max,
        type(uint256).max,
        2 ** 180,
        2 ** 80,
        308532104497726132904056721729503219684262974806296224377864192,
        2 ** 50,
        2,
        4,
        6,
        8,
        10
    ];

    function testMulDiv() external {
        FullMathMock mock = new FullMathMock();
        for (uint256 i = 0; i < len; i++) {
            for (uint256 j = 0; j < len; j++) {
                for (uint256 k = 0; k < len; k++) {
                    uint256 res = check(values[i], values[j], values[k]);
                    if (res != 0) {
                        vm.expectRevert();
                        mock.mulDiv(values[i], values[j], values[k]);
                    } else {
                        mock.mulDiv(values[i], values[j], values[k]);
                    }
                }
            }
        }
    }

    function check2(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) public pure returns (uint256 result, uint256 mulmodResult) {
        unchecked {
            result = FullMath.mulDiv(a, b, denominator);
            mulmodResult = mulmod(a, b, denominator);
        }
    }

    function testMulDivRoundingUp() external {
        FullMathMock mock = new FullMathMock();

        for (uint256 i = 0; i < len; i++) {
            for (uint256 j = 0; j < len; j++) {
                for (uint256 k = 0; k < len; k++) {
                    uint256 res = check(values[i], values[j], values[k]);
                    if (res != 0) {
                        vm.expectRevert();
                        mock.mulDivRoundingUp(values[i], values[j], values[k]);
                    } else {
                        (uint256 result, uint256 mulmodResult) = check2(
                            values[i],
                            values[j],
                            values[k]
                        );
                        if (result == type(uint256).max) {
                            console2.log("ijk:", i, j, k);
                            console2.log(
                                "result: %i, mulmodResult: %i",
                                result,
                                mulmodResult
                            );
                        }
                        mock.mulDivRoundingUp(values[i], values[j], values[k]);
                    }
                }
            }
        }
    }
}
