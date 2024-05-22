// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");

    function testConstructor() external {
        address admin = address(
            bytes20(keccak256("default-access-control-admin"))
        );
        DefaultAccessControl utility = new DefaultAccessControl(admin);
        assertEq(utility.getRoleMemberCount(utility.ADMIN_ROLE()), 1);
        assertEq(utility.getRoleMemberCount(utility.ADMIN_DELEGATE_ROLE()), 0);
        assertEq(utility.getRoleMemberCount(utility.OPERATOR()), 1);
        assertEq(utility.ADMIN_ROLE(), ADMIN_ROLE);
        assertEq(utility.ADMIN_DELEGATE_ROLE(), ADMIN_DELEGATE_ROLE);
        assertEq(utility.OPERATOR(), OPERATOR);

        assertEq(
            utility.getRoleAdmin(utility.ADMIN_ROLE()),
            utility.ADMIN_ROLE()
        );
        assertEq(
            utility.getRoleAdmin(ADMIN_DELEGATE_ROLE),
            utility.ADMIN_ROLE()
        );
        assertEq(utility.getRoleAdmin(utility.OPERATOR()), ADMIN_DELEGATE_ROLE);
    }

    function testIsAdmin() external {
        address admin = address(
            bytes20(keccak256("default-access-control-admin"))
        );
        DefaultAccessControl utility = new DefaultAccessControl(admin);
        assertTrue(utility.isAdmin(admin));

        address operator = address(
            bytes20(keccak256("default-access-control-operator"))
        );

        assertFalse(utility.isAdmin(operator));

        address adminDelegate = address(
            bytes20(keccak256("default-access-control-admin-delegate"))
        );

        assertFalse(utility.isAdmin(adminDelegate));

        vm.prank(admin);
        utility.grantRole(ADMIN_DELEGATE_ROLE, adminDelegate);

        assertTrue(utility.isAdmin(adminDelegate));
    }

    function testIsOperator() external {
        address admin = address(
            bytes20(keccak256("default-access-control-admin"))
        );
        DefaultAccessControl utility = new DefaultAccessControl(admin);
        assertTrue(utility.isOperator(admin));

        address operator = address(
            bytes20(keccak256("default-access-control-operator"))
        );

        assertFalse(utility.isOperator(operator));

        address adminDelegate = address(
            bytes20(keccak256("default-access-control-admin-delegate"))
        );

        assertFalse(utility.isOperator(adminDelegate));

        vm.prank(admin);
        utility.grantRole(ADMIN_DELEGATE_ROLE, adminDelegate);

        assertFalse(utility.isOperator(adminDelegate));

        vm.prank(adminDelegate);
        utility.grantRole(OPERATOR, operator);

        assertTrue(utility.isOperator(operator));
    }

    function testRequireAdmin() external {
        address admin = address(
            bytes20(keccak256("default-access-control-admin"))
        );
        DefaultAccessControl utility = new DefaultAccessControl(admin);
        utility.requireAdmin(admin);

        address operator = address(
            bytes20(keccak256("default-access-control-operator"))
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        utility.requireAdmin(operator);

        address adminDelegate = address(
            bytes20(keccak256("default-access-control-admin-delegate"))
        );
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        utility.requireAdmin(adminDelegate);

        vm.prank(admin);
        utility.grantRole(ADMIN_DELEGATE_ROLE, adminDelegate);

        utility.requireAdmin(adminDelegate);
    }

    function testRequireAtLeastOperator() external {
        address admin = address(
            bytes20(keccak256("default-access-control-admin"))
        );
        DefaultAccessControl utility = new DefaultAccessControl(admin);
        utility.requireAtLeastOperator(admin);

        address operator = address(
            bytes20(keccak256("default-access-control-operator"))
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        utility.requireAtLeastOperator(operator);

        address adminDelegate = address(
            bytes20(keccak256("default-access-control-admin-delegate"))
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        utility.requireAtLeastOperator(adminDelegate);

        vm.prank(admin);
        utility.grantRole(ADMIN_DELEGATE_ROLE, adminDelegate);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        utility.requireAtLeastOperator(operator);

        vm.prank(adminDelegate);
        utility.grantRole(OPERATOR, operator);

        utility.requireAtLeastOperator(operator);
    }
}
