// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        AllowAllValidator validator = new AllowAllValidator();
        assertNotEq(address(validator), address(0));
    }

    function testValidate() external {
        AllowAllValidator validator = new AllowAllValidator();

        address from = address(1);
        address to = address(2);
        bytes memory data = new bytes(0);

        validator.validate(from, to, data);
    }
}
