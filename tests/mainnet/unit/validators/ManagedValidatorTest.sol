// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        assertNotEq(address(validator), address(0));
        assertEq(validator.userRoles(admin), validator.ADMIN_ROLE_MASK());

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testGrantPublicRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantPublicRole(0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testRevokePublicRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokePublicRole(0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testGrantRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantRole(address(0), 0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testRevokeRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokeRole(address(0), 0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testSetCustomValidatorFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setCustomValidator(address(0), address(0));
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setCustomValidator(address(0), address(validator));
        vm.stopPrank();
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testGrantContractRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantContractRole(address(0), 0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testRevokeContractRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokeContractRole(address(0), 0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testGrantContractSignatureRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantContractSignatureRole(address(0), bytes4(0), 0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testRevokeContractSignatureRoleFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokeContractSignatureRole(address(0), bytes4(0), 0);
        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testGrantPublicRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        assertEq(validator.publicRoles(), 0);
        vm.prank(admin);
        validator.grantPublicRole(0);
        assertEq(validator.publicRoles(), 1);

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 1);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 1);
        assertEq(e[0].topics[0], IManagedValidator.PublicRoleGranted.selector);
        assertEq(e[0].data, abi.encode(uint256(0)));
    }

    function testRevokePublicRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        assertEq(validator.publicRoles(), 0);
        vm.prank(admin);
        validator.grantPublicRole(0);
        assertEq(validator.publicRoles(), 1);

        vm.prank(admin);
        validator.revokePublicRole(1);
        // nothing happens
        assertEq(validator.publicRoles(), 1);

        vm.prank(admin);
        validator.revokePublicRole(0);
        assertEq(validator.publicRoles(), 0);

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 3);
        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 1);
        assertEq(e[0].topics[0], IManagedValidator.PublicRoleGranted.selector);
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 1);
        assertEq(e[1].topics[0], IManagedValidator.PublicRoleRevoked.selector);
        assertEq(e[1].data, abi.encode(uint256(1)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 1);
        assertEq(e[2].topics[0], IManagedValidator.PublicRoleRevoked.selector);
        assertEq(e[2].data, abi.encode(uint256(0)));
    }

    function testGrantRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantRole(user, 200);
        assertEq(validator.userRoles(user), 1 | (1 << 200));

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1 | (1 << 200));

        vm.prank(admin);
        validator.grantRole(user, 201);
        assertEq(validator.userRoles(user), 1 | (1 << 200) | (1 << 201));

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(e[1].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[1].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[1].data, abi.encode(uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(e[2].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[2].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[2].data, abi.encode(uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(e[3].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[3].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[3].data, abi.encode(uint256(201)));
    }

    function testRevokeRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        vm.prank(admin);
        validator.grantRole(user, 200);
        vm.prank(admin);
        validator.grantRole(user, 201);

        assertEq(validator.userRoles(user), 1 | (1 << 200) | (1 << 201));

        vm.prank(admin);
        validator.revokeRole(user, 0);
        assertEq(validator.userRoles(user), (1 << 200) | (1 << 201));

        vm.prank(admin);
        validator.revokeRole(user, 0);
        assertEq(validator.userRoles(user), (1 << 200) | (1 << 201));

        vm.prank(admin);
        validator.revokeRole(user, 201);
        assertEq(validator.userRoles(user), 1 << 200);

        vm.prank(admin);
        validator.revokeRole(user, 200);
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 1);
        assertEq(validator.userRoles(user), 2);

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 8);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(e[1].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[1].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[1].data, abi.encode(uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(e[2].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[2].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[2].data, abi.encode(uint256(201)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(e[3].topics[0], IManagedValidator.RoleRevoked.selector);
        assertEq(e[3].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[3].data, abi.encode(uint256(0)));

        assertEq(e[4].emitter, address(validator));
        assertEq(e[4].topics.length, 2);
        assertEq(e[4].topics[0], IManagedValidator.RoleRevoked.selector);
        assertEq(e[4].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[4].data, abi.encode(uint256(0)));

        assertEq(e[5].emitter, address(validator));
        assertEq(e[5].topics.length, 2);
        assertEq(e[5].topics[0], IManagedValidator.RoleRevoked.selector);
        assertEq(e[5].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[5].data, abi.encode(uint256(201)));

        assertEq(e[6].emitter, address(validator));
        assertEq(e[6].topics.length, 2);
        assertEq(e[6].topics[0], IManagedValidator.RoleRevoked.selector);
        assertEq(e[6].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[6].data, abi.encode(uint256(200)));

        assertEq(e[7].emitter, address(validator));
        assertEq(e[7].topics.length, 2);
        assertEq(e[7].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[7].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[7].data, abi.encode(uint256(1)));
    }

    function testSetCustomValidator() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        address customValidator = address(
            bytes20(keccak256("custom-validator"))
        );

        assertEq(validator.customValidator(randomContract), address(0));

        vm.prank(admin);
        validator.setCustomValidator(randomContract, customValidator);
        assertEq(validator.customValidator(randomContract), customValidator);

        vm.prank(admin);
        validator.setCustomValidator(randomContract, customValidator);
        assertEq(validator.customValidator(randomContract), customValidator);

        vm.prank(admin);
        validator.setCustomValidator(randomContract, address(0));
        assertEq(validator.customValidator(randomContract), address(0));

        vm.prank(admin);
        validator.setCustomValidator(randomContract, address(0));
        assertEq(validator.customValidator(randomContract), address(0));

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.CustomValidatorSet.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(customValidator));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(e[1].topics[0], IManagedValidator.CustomValidatorSet.selector);
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(customValidator));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(e[2].topics[0], IManagedValidator.CustomValidatorSet.selector);
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(address(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(e[3].topics[0], IManagedValidator.CustomValidatorSet.selector);
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(address(0)));
    }

    function testGrantContractRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        assertEq(validator.allowAllSignaturesRoles(randomContract), 0);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);
        assertEq(validator.allowAllSignaturesRoles(randomContract), 1);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 200);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractRole(randomContract, 201);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200) | (1 << 201)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(uint256(201)));
    }

    function testRevokeContractRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        assertEq(validator.allowAllSignaturesRoles(randomContract), 0);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);
        vm.prank(admin);
        validator.grantContractRole(randomContract, 200);
        vm.prank(admin);
        validator.grantContractRole(randomContract, 201);

        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200) | (1 << 201)
        );

        vm.prank(admin);
        validator.revokeContractRole(randomContract, 0);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            (1 << 200) | (1 << 201)
        );

        vm.prank(admin);
        validator.revokeContractRole(randomContract, 0);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            (1 << 200) | (1 << 201)
        );

        vm.prank(admin);
        validator.revokeContractRole(randomContract, 201);
        assertEq(validator.allowAllSignaturesRoles(randomContract), 1 << 200);

        vm.prank(admin);
        validator.revokeContractRole(randomContract, 200);
        assertEq(validator.allowAllSignaturesRoles(randomContract), 0);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 1);
        assertEq(validator.allowAllSignaturesRoles(randomContract), 2);

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 8);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(uint256(201)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractRoleRevoked.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(uint256(0)));

        assertEq(e[4].emitter, address(validator));
        assertEq(e[4].topics.length, 2);
        assertEq(
            e[4].topics[0],
            IManagedValidator.ContractRoleRevoked.selector
        );
        assertEq(e[4].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[4].data, abi.encode(uint256(0)));

        assertEq(e[5].emitter, address(validator));
        assertEq(e[5].topics.length, 2);
        assertEq(
            e[5].topics[0],
            IManagedValidator.ContractRoleRevoked.selector
        );
        assertEq(e[5].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[5].data, abi.encode(uint256(201)));

        assertEq(e[6].emitter, address(validator));
        assertEq(e[6].topics.length, 2);
        assertEq(
            e[6].topics[0],
            IManagedValidator.ContractRoleRevoked.selector
        );
        assertEq(e[6].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[6].data, abi.encode(uint256(200)));

        assertEq(e[7].emitter, address(validator));
        assertEq(e[7].topics.length, 2);
        assertEq(
            e[7].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[7].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[7].data, abi.encode(uint256(1)));
    }

    function testGrantContractSignatureRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            0
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            200
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            201
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200) | (1 << 201)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(randomSignature, uint256(201)));
    }

    function testRevokeContractSignatureRole() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            0
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            200
        );
        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            201
        );

        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200) | (1 << 201)
        );

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            (1 << 200) | (1 << 201)
        );

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            (1 << 200) | (1 << 201)
        );

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            201
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 << 200
        );

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            200
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            0
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            1
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            2
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 8);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(randomSignature, uint256(201)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[4].emitter, address(validator));
        assertEq(e[4].topics.length, 2);
        assertEq(
            e[4].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[4].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[4].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[5].emitter, address(validator));
        assertEq(e[5].topics.length, 2);
        assertEq(
            e[5].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[5].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[5].data, abi.encode(randomSignature, uint256(201)));

        assertEq(e[6].emitter, address(validator));
        assertEq(e[6].topics.length, 2);
        assertEq(
            e[6].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[6].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[6].data, abi.encode(randomSignature, uint256(200)));

        assertEq(e[7].emitter, address(validator));
        assertEq(e[7].topics.length, 2);
        assertEq(
            e[7].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[7].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[7].data, abi.encode(randomSignature, uint256(1)));
    }

    function testAllowAllSignaturesRoles() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        assertEq(validator.allowAllSignaturesRoles(randomContract), 0);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);
        assertEq(validator.allowAllSignaturesRoles(randomContract), 1);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 200);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractRole(randomContract, 201);
        assertEq(
            validator.allowAllSignaturesRoles(randomContract),
            1 | (1 << 200) | (1 << 201)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(uint256(201)));
    }

    function testAllowSignatureRoles() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            0
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            200
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200)
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            201
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1 | (1 << 200) | (1 << 201)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[0].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(200)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(randomSignature, uint256(201)));
    }

    function testValidate() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        vm.prank(admin);
        validator.validate(
            user,
            randomContract,
            abi.encodeWithSelector(randomSignature)
        );

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);
        assertEq(validator.allowAllSignaturesRoles(randomContract), 1);

        vm.prank(admin);
        validator.validate(
            user,
            randomContract,
            abi.encodeWithSelector(randomSignature)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 4);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(uint256(0)));
    }

    function testValidateFailsWithInvalidData() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        vm.expectRevert(abi.encodeWithSignature("InvalidData()"));
        validator.validate(user, randomContract, new bytes(0));

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 2);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(0)));
    }

    function testValidateFailsWithForbidden() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.validate(
            user,
            randomContract,
            abi.encodeWithSelector(randomSignature)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 1);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));
    }

    function testValidateFailsWithCustomValidation() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        address invalidCustomValidator = address(
            bytes20(keccak256("invalid-custom-validator"))
        );

        // invalid validator
        vm.prank(admin);
        validator.setCustomValidator(randomContract, invalidCustomValidator);

        assertEq(
            validator.customValidator(randomContract),
            invalidCustomValidator
        );

        vm.expectRevert();
        validator.validate(
            user,
            randomContract,
            abi.encodeWithSelector(randomSignature)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 3);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(e[2].topics[0], IManagedValidator.CustomValidatorSet.selector);
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(invalidCustomValidator));
    }

    function testValidateWithCustomValidation() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        AllowAllValidator customValidator = new AllowAllValidator();

        vm.prank(admin);
        validator.setCustomValidator(randomContract, address(customValidator));
        validator.validate(
            user,
            randomContract,
            abi.encodeWithSelector(randomSignature)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 3);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(e[2].topics[0], IManagedValidator.CustomValidatorSet.selector);
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(address(customValidator)));
    }

    function testHasPermission() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        // always true
        assertTrue(
            validator.hasPermission(admin, randomContract, randomSignature)
        );

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        assertFalse(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        assertTrue(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertFalse(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);

        assertTrue(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.revokeRole(user, 0);

        assertFalse(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.grantPublicRole(0);

        assertTrue(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );
        assertTrue(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        vm.prank(admin);
        validator.revokeContractRole(randomContract, 0);
        assertTrue(
            validator.hasPermission(user, randomContract, randomSignature)
        );

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 8);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(uint256(0)));

        assertEq(e[4].emitter, address(validator));
        assertEq(e[4].topics.length, 2);
        assertEq(e[4].topics[0], IManagedValidator.RoleRevoked.selector);
        assertEq(e[4].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[4].data, abi.encode(uint256(0)));

        assertEq(e[5].emitter, address(validator));
        assertEq(e[5].topics.length, 1);
        assertEq(e[5].topics[0], IManagedValidator.PublicRoleGranted.selector);
        assertEq(e[5].data, abi.encode(uint256(0)));

        assertEq(e[6].emitter, address(validator));
        assertEq(e[6].topics.length, 2);
        assertEq(
            e[6].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[6].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[6].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[7].emitter, address(validator));
        assertEq(e[7].topics.length, 2);
        assertEq(
            e[7].topics[0],
            IManagedValidator.ContractRoleRevoked.selector
        );
        assertEq(e[7].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[7].data, abi.encode(uint256(0)));
    }

    function testRequirePermission() external {
        vm.recordLogs();
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        address randomContract = address(bytes20(keccak256("random-contract")));
        bytes4 randomSignature = bytes4(keccak256("random-signature"));

        // always true

        validator.requirePermission(admin, randomContract, randomSignature);

        address user = address(bytes20(keccak256("random-user")));
        assertEq(validator.userRoles(user), 0);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.grantRole(user, 0);
        assertEq(validator.userRoles(user), 1);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );

        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.revokeContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.grantContractRole(randomContract, 0);

        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.revokeRole(user, 0);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.grantPublicRole(0);

        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.grantContractSignatureRole(
            randomContract,
            randomSignature,
            0
        );
        assertEq(
            validator.allowSignatureRoles(randomContract, randomSignature),
            1
        );
        validator.requirePermission(user, randomContract, randomSignature);

        vm.prank(admin);
        validator.revokeContractRole(randomContract, 0);
        validator.requirePermission(user, randomContract, randomSignature);

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 8);

        assertEq(e[0].emitter, address(validator));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], IManagedValidator.RoleGranted.selector);
        assertEq(e[0].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[0].data, abi.encode(uint256(0)));

        assertEq(e[1].emitter, address(validator));
        assertEq(e[1].topics.length, 2);
        assertEq(
            e[1].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[1].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[1].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[2].emitter, address(validator));
        assertEq(e[2].topics.length, 2);
        assertEq(
            e[2].topics[0],
            IManagedValidator.ContractSignatureRoleRevoked.selector
        );
        assertEq(e[2].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[2].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[3].emitter, address(validator));
        assertEq(e[3].topics.length, 2);
        assertEq(
            e[3].topics[0],
            IManagedValidator.ContractRoleGranted.selector
        );
        assertEq(e[3].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[3].data, abi.encode(uint256(0)));

        assertEq(e[4].emitter, address(validator));
        assertEq(e[4].topics.length, 2);
        assertEq(e[4].topics[0], IManagedValidator.RoleRevoked.selector);
        assertEq(e[4].topics[1], bytes32(uint256(uint160(user))));
        assertEq(e[4].data, abi.encode(uint256(0)));

        assertEq(e[5].emitter, address(validator));
        assertEq(e[5].topics.length, 1);
        assertEq(e[5].topics[0], IManagedValidator.PublicRoleGranted.selector);
        assertEq(e[5].data, abi.encode(uint256(0)));

        assertEq(e[6].emitter, address(validator));
        assertEq(e[6].topics.length, 2);
        assertEq(
            e[6].topics[0],
            IManagedValidator.ContractSignatureRoleGranted.selector
        );
        assertEq(e[6].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[6].data, abi.encode(randomSignature, uint256(0)));

        assertEq(e[7].emitter, address(validator));
        assertEq(e[7].topics.length, 2);
        assertEq(
            e[7].topics[0],
            IManagedValidator.ContractRoleRevoked.selector
        );
        assertEq(e[7].topics[1], bytes32(uint256(uint160(randomContract))));
        assertEq(e[7].data, abi.encode(uint256(0)));
    }
}
