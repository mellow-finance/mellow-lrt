// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function testConstructor() external {
        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 5);

        assertEq(e[0].emitter, address(utility));
        assertEq(e[0].topics.length, 4);
        assertEq(e[0].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[0].topics[1], OPERATOR);
        assertEq(e[0].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[0].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[0].data, new bytes(0));

        assertEq(e[1].emitter, address(utility));
        assertEq(e[1].topics.length, 4);
        assertEq(e[1].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[1].topics[1], ADMIN_ROLE);
        assertEq(e[1].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[1].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[1].data, new bytes(0));

        assertEq(e[2].emitter, address(utility));
        assertEq(e[2].topics.length, 4);
        assertEq(e[2].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[2].topics[1], ADMIN_ROLE);
        assertEq(e[2].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[2].topics[3], ADMIN_ROLE);
        assertEq(e[2].data, new bytes(0));

        assertEq(e[3].emitter, address(utility));
        assertEq(e[3].topics.length, 4);
        assertEq(e[3].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[3].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[3].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[3].topics[3], ADMIN_ROLE);
        assertEq(e[3].data, new bytes(0));

        assertEq(e[4].emitter, address(utility));
        assertEq(e[4].topics.length, 4);
        assertEq(e[4].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[4].topics[1], OPERATOR);
        assertEq(e[4].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[4].topics[3], ADMIN_DELEGATE_ROLE);
        assertEq(e[4].data, new bytes(0));
    }

    function testIsAdmin() external {
        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 6);

        assertEq(e[0].emitter, address(utility));
        assertEq(e[0].topics.length, 4);
        assertEq(e[0].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[0].topics[1], OPERATOR);
        assertEq(e[0].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[0].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[0].data, new bytes(0));

        assertEq(e[1].emitter, address(utility));
        assertEq(e[1].topics.length, 4);
        assertEq(e[1].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[1].topics[1], ADMIN_ROLE);
        assertEq(e[1].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[1].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[1].data, new bytes(0));

        assertEq(e[2].emitter, address(utility));
        assertEq(e[2].topics.length, 4);
        assertEq(e[2].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[2].topics[1], ADMIN_ROLE);
        assertEq(e[2].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[2].topics[3], ADMIN_ROLE);
        assertEq(e[2].data, new bytes(0));

        assertEq(e[3].emitter, address(utility));
        assertEq(e[3].topics.length, 4);
        assertEq(e[3].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[3].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[3].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[3].topics[3], ADMIN_ROLE);
        assertEq(e[3].data, new bytes(0));

        assertEq(e[4].emitter, address(utility));
        assertEq(e[4].topics.length, 4);
        assertEq(e[4].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[4].topics[1], OPERATOR);
        assertEq(e[4].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[4].topics[3], ADMIN_DELEGATE_ROLE);
        assertEq(e[4].data, new bytes(0));

        assertEq(e[5].emitter, address(utility));
        assertEq(e[5].topics.length, 4);
        assertEq(e[5].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[5].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[5].topics[2], bytes32(uint256(uint160(adminDelegate))));
        assertEq(e[5].topics[3], bytes32(uint256(uint160(admin))));
        assertEq(e[5].data, new bytes(0));
    }

    function testIsOperator() external {
        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 7);

        assertEq(e[0].emitter, address(utility));
        assertEq(e[0].topics.length, 4);
        assertEq(e[0].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[0].topics[1], OPERATOR);
        assertEq(e[0].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[0].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[0].data, new bytes(0));

        assertEq(e[1].emitter, address(utility));
        assertEq(e[1].topics.length, 4);
        assertEq(e[1].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[1].topics[1], ADMIN_ROLE);
        assertEq(e[1].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[1].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[1].data, new bytes(0));

        assertEq(e[2].emitter, address(utility));
        assertEq(e[2].topics.length, 4);
        assertEq(e[2].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[2].topics[1], ADMIN_ROLE);
        assertEq(e[2].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[2].topics[3], ADMIN_ROLE);
        assertEq(e[2].data, new bytes(0));

        assertEq(e[3].emitter, address(utility));
        assertEq(e[3].topics.length, 4);
        assertEq(e[3].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[3].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[3].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[3].topics[3], ADMIN_ROLE);
        assertEq(e[3].data, new bytes(0));

        assertEq(e[4].emitter, address(utility));
        assertEq(e[4].topics.length, 4);
        assertEq(e[4].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[4].topics[1], OPERATOR);
        assertEq(e[4].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[4].topics[3], ADMIN_DELEGATE_ROLE);
        assertEq(e[4].data, new bytes(0));

        assertEq(e[5].emitter, address(utility));
        assertEq(e[5].topics.length, 4);
        assertEq(e[5].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[5].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[5].topics[2], bytes32(uint256(uint160(adminDelegate))));
        assertEq(e[5].topics[3], bytes32(uint256(uint160(admin))));
        assertEq(e[5].data, new bytes(0));

        assertEq(e[6].emitter, address(utility));
        assertEq(e[6].topics.length, 4);
        assertEq(e[6].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[6].topics[1], OPERATOR);
        assertEq(e[6].topics[2], bytes32(uint256(uint160(operator))));
        assertEq(e[6].topics[3], bytes32(uint256(uint160(adminDelegate))));
        assertEq(e[6].data, new bytes(0));
    }

    function testRequireAdmin() external {
        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 6);

        assertEq(e[0].emitter, address(utility));
        assertEq(e[0].topics.length, 4);
        assertEq(e[0].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[0].topics[1], OPERATOR);
        assertEq(e[0].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[0].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[0].data, new bytes(0));

        assertEq(e[1].emitter, address(utility));
        assertEq(e[1].topics.length, 4);
        assertEq(e[1].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[1].topics[1], ADMIN_ROLE);
        assertEq(e[1].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[1].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[1].data, new bytes(0));

        assertEq(e[2].emitter, address(utility));
        assertEq(e[2].topics.length, 4);
        assertEq(e[2].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[2].topics[1], ADMIN_ROLE);
        assertEq(e[2].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[2].topics[3], ADMIN_ROLE);
        assertEq(e[2].data, new bytes(0));

        assertEq(e[3].emitter, address(utility));
        assertEq(e[3].topics.length, 4);
        assertEq(e[3].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[3].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[3].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[3].topics[3], ADMIN_ROLE);
        assertEq(e[3].data, new bytes(0));

        assertEq(e[4].emitter, address(utility));
        assertEq(e[4].topics.length, 4);
        assertEq(e[4].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[4].topics[1], OPERATOR);
        assertEq(e[4].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[4].topics[3], ADMIN_DELEGATE_ROLE);
        assertEq(e[4].data, new bytes(0));

        assertEq(e[5].emitter, address(utility));
        assertEq(e[5].topics.length, 4);
        assertEq(e[5].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[5].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[5].topics[2], bytes32(uint256(uint160(adminDelegate))));
        assertEq(e[5].topics[3], bytes32(uint256(uint160(admin))));
        assertEq(e[5].data, new bytes(0));
    }

    function testRequireAtLeastOperator() external {
        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 7);

        assertEq(e[0].emitter, address(utility));
        assertEq(e[0].topics.length, 4);
        assertEq(e[0].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[0].topics[1], OPERATOR);
        assertEq(e[0].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[0].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[0].data, new bytes(0));

        assertEq(e[1].emitter, address(utility));
        assertEq(e[1].topics.length, 4);
        assertEq(e[1].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[1].topics[1], ADMIN_ROLE);
        assertEq(e[1].topics[2], bytes32(uint256(uint160(admin))));
        assertEq(e[1].topics[3], bytes32(uint256(uint160(address(this)))));
        assertEq(e[1].data, new bytes(0));

        assertEq(e[2].emitter, address(utility));
        assertEq(e[2].topics.length, 4);
        assertEq(e[2].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[2].topics[1], ADMIN_ROLE);
        assertEq(e[2].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[2].topics[3], ADMIN_ROLE);
        assertEq(e[2].data, new bytes(0));

        assertEq(e[3].emitter, address(utility));
        assertEq(e[3].topics.length, 4);
        assertEq(e[3].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[3].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[3].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[3].topics[3], ADMIN_ROLE);
        assertEq(e[3].data, new bytes(0));

        assertEq(e[4].emitter, address(utility));
        assertEq(e[4].topics.length, 4);
        assertEq(e[4].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[4].topics[1], OPERATOR);
        assertEq(e[4].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[4].topics[3], ADMIN_DELEGATE_ROLE);
        assertEq(e[4].data, new bytes(0));

        assertEq(e[5].emitter, address(utility));
        assertEq(e[5].topics.length, 4);
        assertEq(e[5].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[5].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[5].topics[2], bytes32(uint256(uint160(adminDelegate))));
        assertEq(e[5].topics[3], bytes32(uint256(uint160(admin))));
        assertEq(e[5].data, new bytes(0));

        assertEq(e[6].emitter, address(utility));
        assertEq(e[6].topics.length, 4);
        assertEq(e[6].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[6].topics[1], OPERATOR);
        assertEq(e[6].topics[2], bytes32(uint256(uint160(operator))));
        assertEq(e[6].topics[3], bytes32(uint256(uint160(adminDelegate))));
        assertEq(e[6].data, new bytes(0));
    }
}
