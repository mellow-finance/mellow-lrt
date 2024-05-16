// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        assertNotEq(address(validator), address(0));
        assertEq(validator.userRoles(admin), validator.ADMIN_ROLE_MASK());
    }

    function testGrantPublicRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantPublicRole(0);
    }

    function testRevokePublicRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokePublicRole(0);
    }

    function testGrantRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantRole(address(0), 0);
    }

    function testRevokeRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokeRole(address(0), 0);
    }

    function testSetCustomValidatorFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setCustomValidator(address(0), address(0));
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setCustomValidator(address(0), address(validator));
        vm.stopPrank();
    }

    function testGrantContractRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantContractRole(address(0), 0);
    }

    function testRevokeContractRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokeContractRole(address(0), 0);
    }

    function testGrantContractSignatureRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.grantContractSignatureRole(address(0), bytes4(0), 0);
    }

    function testRevokeContractSignatureRoleFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.revokeContractSignatureRole(address(0), bytes4(0), 0);
    }

    function testGrantPublicRole() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ManagedValidator validator = new ManagedValidator(admin);

        assertEq(validator.publicRoles(), 0);
        vm.prank(admin);
        validator.grantPublicRole(0);
        assertEq(validator.publicRoles(), 1);
    }

    function testRevokePublicRole() external {
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
    }

    function testGrantRole() external {
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
    }

    function testRevokeRole() external {
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
    }

    function testSetCustomValidator() external {
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
    }

    function testGrantContractRole() external {
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
    }

    function testRevokeContractRole() external {
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
    }

    function testGrantContractSignatureRole() external {
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
    }

    function testRevokeContractSignatureRole() external {
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
    }

    function testAllowAllSignaturesRoles() external {
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
    }

    function testAllowSignatureRoles() external {
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
    }

    function testValidate() external {
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
    }

    function testValidateFailsWithInvalidData() external {
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
    }

    function testValidateFailsWithForbidden() external {
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
    }

    function testValidateFailsWithCustomValidation() external {
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
    }

    function testValidateWithCustomValidation() external {
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
    }

    function testHasPermission() external {
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
    }

    function testRequirePermission() external {
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
    }
}
