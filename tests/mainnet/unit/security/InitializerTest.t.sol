// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../../src/security/Initializer.sol";
import "../../Constants.sol";

contract Unit is Test {
    function testInitialize() external {
        Initializer initializer = new Initializer();
        address admin = vm.createWallet("admin").addr;
        initializer.initialize("name", "symbol", admin);
        assertTrue(initializer.hasRole(initializer.ADMIN_ROLE(), admin));
        assertTrue(initializer.hasRole(initializer.OPERATOR(), admin));
        assertNotEq(address(initializer.configurator()), address(0));
        assertEq(initializer.name(), "name");
        assertEq(initializer.symbol(), "symbol");
    }

    function testInvalidInitialization() external {
        Initializer initializer = new Initializer();
        address admin = vm.createWallet("admin").addr;
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        initializer.initialize("name", "symbol", address(0));

        string memory longString = "01234567890123456789012345678901"; // 32 symbols
        string memory maxAllowedString = "0123456789012345678901234567890"; // 32 symbols

        vm.expectRevert("Too long name");
        initializer.initialize(longString, "symbol", admin);
        vm.expectRevert("Too long symbol");
        initializer.initialize("name", longString, admin);

        initializer.initialize(maxAllowedString, maxAllowedString, admin);
        vm.expectRevert();
        initializer.initialize("name", "symbol", admin);
    }
}
