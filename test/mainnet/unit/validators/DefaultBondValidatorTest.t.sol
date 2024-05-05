// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);
        assertNotEq(address(validator), address(0));
        validator.requireAdmin(admin);
    }

    function testValidateFailsWithInvalidLength() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);

        address from = address(1);
        address to = address(2);
        bytes memory data = new bytes(0);

        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        validator.validate(from, to, data);
    }

    function testValidateFailsWithInvalidSelector() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);

        address from = address(1);
        address to = address(2);
        bytes memory data = abi.encodeWithSignature(
            "invalidSelector(address,uint256)",
            address(0),
            0
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidSelector()"));
        validator.validate(from, to, data);
    }

    function testValidateFailsWithZeroAmount() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);

        address from = address(1);
        address to = address(2);
        bytes memory data = abi.encodeWithSignature(
            "deposit(address,uint256)",
            address(0),
            0
        );
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        validator.validate(from, to, data);
    }

    function testValidateFailsWithUnsupportedBond() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);

        address from = address(1);
        address to = address(2);
        uint256 amount = 1 ether;
        bytes memory data = abi.encodeWithSignature(
            "deposit(address,uint256)",
            address(0),
            amount
        );
        vm.expectRevert(abi.encodeWithSignature("UnsupportedBond()"));
        validator.validate(from, to, data);
    }

    function testSetSupportedBondFailsForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);
        address randomBond = address(bytes20(keccak256("random-bond")));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setSupportedBond(randomBond, true);
    }

    function testSetSupportedBond() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);
        address randomBond = address(bytes20(keccak256("random-bond")));

        assertFalse(validator.isSupportedBond(randomBond));

        vm.prank(admin);
        validator.setSupportedBond(randomBond, true);

        assertTrue(validator.isSupportedBond(randomBond));
    }

    function testValidateReversAfterBondDisabling() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);
        address randomBond = address(bytes20(keccak256("random-bond")));
        vm.prank(admin);
        validator.setSupportedBond(randomBond, true);

        address from = address(1);
        address to = address(2);
        uint256 amount = 1 ether;
        bytes memory data = abi.encodeWithSignature(
            "deposit(address,uint256)",
            randomBond,
            amount
        );
        validator.validate(from, to, data);

        vm.prank(admin);
        validator.setSupportedBond(randomBond, false);

        vm.expectRevert(abi.encodeWithSignature("UnsupportedBond()"));
        validator.validate(from, to, data);
    }

    function testValidate() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        DefaultBondValidator validator = new DefaultBondValidator(admin);
        address randomBond = address(bytes20(keccak256("random-bond")));
        vm.prank(admin);
        validator.setSupportedBond(randomBond, true);

        address from = address(1);
        address to = address(2);
        uint256 amount = 1 ether;
        bytes memory data = abi.encodeWithSignature(
            "deposit(address,uint256)",
            randomBond,
            amount
        );
        validator.validate(from, to, data);
    }
}
