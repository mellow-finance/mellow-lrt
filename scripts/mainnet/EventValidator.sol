// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

abstract contract EventValidator is StdAssertions, CommonBase {
    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");

    bytes32 public constant CONFIGURATOR_BASE_DELAY_SLOT =
        bytes32(uint256(0x1));
    bytes32 public constant CONFIGURATOR_DEPOSIT_CALLBACK_DELAY_SLOT =
        bytes32(uint256(0x4));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_CALLBACK_DELAY_SLOT =
        bytes32(uint256(0x7));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_FEE_D9_DELAY_SLOT =
        bytes32(uint256(0xa));
    bytes32 public constant CONFIGURATOR_MAXIMAL_TOTAL_SUPPLY_DELAY_SLOT =
        bytes32(uint256(0xd));
    bytes32 public constant CONFIGURATOR_IS_DEPOSIT_LOCKED_DELAY_SLOT =
        bytes32(uint256(0x10));
    bytes32 public constant CONFIGURATOR_ARE_TRANSFERS_LOCKED_DELAY_SLOT =
        bytes32(uint256(0x13));
    bytes32
        public constant CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_DELAY_SLOT =
        bytes32(uint256(0x16));
    bytes32 public constant CONFIGURATOR_RATIOS_ORACLE_DELAY_SLOT =
        bytes32(uint256(0x19));
    bytes32 public constant CONFIGURATOR_PRICE_ORACLE_DELAY_SLOT =
        bytes32(uint256(0x1c));
    bytes32 public constant CONFIGURATOR_VALIDATOR_DELAY_SLOT =
        bytes32(uint256(0x1f));
    bytes32 public constant CONFIGURATOR_EMERGENCY_WITHDRAWAL_DELAY_SLOT =
        bytes32(uint256(0x22));
    bytes32 public constant CONFIGURATOR_DEPOSIT_CALLBACK_SLOT =
        bytes32(uint256(0x25));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_CALLBACK_SLOT =
        bytes32(uint256(0x28));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_FEE_D9_SLOT =
        bytes32(uint256(0x2b));
    bytes32 public constant CONFIGURATOR_MAXIMAL_TOTAL_SUPPLY_SLOT =
        bytes32(uint256(0x2e));
    bytes32 public constant CONFIGURATOR_IS_DEPOSIT_LOCKED_SLOT =
        bytes32(uint256(0x31));
    bytes32 public constant CONFIGURATOR_ARE_TRANSFERS_LOCKED_SLOT =
        bytes32(uint256(0x34));
    bytes32 public constant CONFIGURATOR_RATIOS_ORACLE_SLOT =
        bytes32(uint256(0x37));
    bytes32 public constant CONFIGURATOR_PRICE_ORACLE_SLOT =
        bytes32(uint256(0x3a));
    bytes32 public constant CONFIGURATOR_VALIDATOR_SLOT =
        bytes32(uint256(0x3d));
    bytes32 public constant CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_SLOT =
        bytes32(uint256(0x40));

    function validateEvents(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup,
        Vm.Log[] memory e
    ) public view {
        address[] memory addressSpace = new address[](e.length * 9 + 2);
        uint256 iterator = 0;
        addressSpace[iterator++] = address(0);
        addressSpace[iterator++] = address(deployParams.deployer);
        for (uint256 i = 0; i < e.length; i++) {
            addressSpace[iterator++] = e[i].emitter;
            for (uint256 j = 0; j < e[i].topics.length; j++) {
                addressSpace[iterator++] = address(
                    uint160(uint256(e[i].topics[j]))
                );
            }
        }
        makeUnique(addressSpace);

        // user roles
        {
            address[] memory allowedUsers = new address[](1);
            allowedUsers[0] = deployParams.admin;
            checkManagedValidatorUserRoles(
                addressSpace,
                allowedUsers,
                setup.validator,
                1 << DeployConstants.ADMIN_ROLE_BIT
            );

            allowedUsers[0] = address(setup.defaultBondStrategy);
            checkManagedValidatorUserRoles(
                addressSpace,
                allowedUsers,
                setup.validator,
                1 << DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );

            allowedUsers[0] = address(setup.defaultBondStrategy);
            checkManagedValidatorUserRoles(
                addressSpace,
                allowedUsers,
                setup.validator,
                1 << DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );

            allowedUsers[0] = address(setup.vault);
            checkManagedValidatorUserRoles(
                addressSpace,
                allowedUsers,
                setup.validator,
                1 << DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT
            );

            allowedUsers = new address[](0);
            for (uint256 bit = 0; bit < 256; bit++) {
                if (bit == DeployConstants.ADMIN_ROLE_BIT) continue;
                if (bit == DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT)
                    continue;
                if (bit == DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT)
                    continue;
                checkManagedValidatorUserRoles(
                    addressSpace,
                    allowedUsers,
                    setup.validator,
                    1 << bit
                );
            }
        }

        // public roles
        assertEq(
            setup.validator.publicRoles(),
            1 << DeployConstants.DEPOSITOR_ROLE_BIT,
            "Public roles check failed"
        );

        // contract roles
        {
            address[] memory allowedUsers = new address[](1);
            allowedUsers[0] = address(setup.vault);
            checkManagedValidatorAllowAllSignaturesRoles(
                addressSpace,
                allowedUsers,
                setup.validator,
                1 << DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );

            allowedUsers[0] = address(deployParams.defaultBondModule);
            checkManagedValidatorAllowAllSignaturesRoles(
                addressSpace,
                allowedUsers,
                setup.validator,
                1 << DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT
            );

            allowedUsers = new address[](0);
            for (uint256 bit = 0; bit < 256; bit++) {
                if (bit == DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT)
                    continue;
                if (bit == DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT)
                    continue;
                checkManagedValidatorAllowAllSignaturesRoles(
                    addressSpace,
                    allowedUsers,
                    setup.validator,
                    1 << bit
                );
            }
        }

        // contract-signature roles
        {
            address[] memory allowedContracts = new address[](1);
            bytes4[] memory allowedSignature = new bytes4[](1);
            uint8[] memory roleBits = new uint8[](1);
            allowedContracts[0] = address(setup.vault);
            allowedSignature[0] = IVault.deposit.selector;
            roleBits[0] = DeployConstants.DEPOSITOR_ROLE_BIT;
            for (uint256 i = 0; i < e.length; i++) {
                Vm.Log memory e_ = e[i];
                if (
                    e_.emitter != address(setup.validator) ||
                    e_.topics[0] !=
                    IManagedValidator.ContractSignatureRoleGranted.selector
                ) continue;
                assertEq(e_.topics.length, 2);
                bytes32 topic = e_.topics[1];
                address contract_ = address(uint160(uint256(topic)));
                assertEq(
                    bytes32(uint256(uint160(contract_))),
                    topic,
                    "Invalid event topic"
                );

                (bytes4 signature, ) = abi.decode(e_.data, (bytes4, uint256));
                bool found = false;
                for (uint256 j = 0; j < allowedContracts.length; j++) {
                    if (
                        allowedContracts[j] == contract_ &&
                        allowedSignature[j] == signature
                    ) {
                        found = true;
                        break;
                    }
                }
                assertTrue(found, "Invalid contract");
            }

            for (uint256 i = 0; i < allowedContracts.length; i++) {
                address[] memory contractsForCheck = new address[](1);
                contractsForCheck[0] = allowedContracts[i];
                checkManagedValidatorAllowSignatureRoles(
                    addressSpace,
                    contractsForCheck,
                    setup.validator,
                    1 << roleBits[i],
                    allowedSignature[i]
                );
            }
        }

        // custom validators
        {
            checkManagedValidatorCustomValidators(
                addressSpace,
                setup.validator
            );
        }

        // configurator delegate module approvals
        {
            address[] memory allowedDelegateModules = new address[](1);
            allowedDelegateModules[0] = address(deployParams.defaultBondModule);
            for (uint256 i = 0; i < e.length; i++) {
                Vm.Log memory e_ = e[i];
                if (e_.emitter != address(setup.configurator)) continue;
                if (e_.topics[0] != IVaultConfigurator.Stage.selector) continue;
                if (
                    e_.topics[1] <=
                    CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_SLOT
                ) continue;
                bytes32 slot = e_.topics[1];
                bool found = false;
                for (uint256 j = 0; j < allowedDelegateModules.length; j++) {
                    bytes32 allowedSlot = keccak256(
                        abi.encode(
                            allowedDelegateModules[j],
                            CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_SLOT
                        )
                    );
                    if (allowedSlot != slot) continue;
                    found = true;
                }
                assertTrue(found, "Invalid delegate module address");
            }

            for (uint256 i = 0; i < allowedDelegateModules.length; i++) {
                assertTrue(
                    setup.configurator.isDelegateModuleApproved(
                        allowedDelegateModules[i]
                    ),
                    "Required delegate module not approved"
                );
            }
        }
    }

    function has(
        address[] memory array,
        address user
    ) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++)
            if (array[i] == user) return true;
        return false;
    }

    function checkManagedValidatorUserRoles(
        address[] memory users,
        address[] memory allowedUsers,
        ManagedValidator validator,
        uint256 roleSet
    ) public view {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 roleSet_ = validator.userRoles(users[i]);
            if (has(allowedUsers, users[i])) {
                assertEq(roleSet_, roleSet, "Role check failed");
            } else {
                assertEq((roleSet_ & roleSet), 0, "Role check failed");
            }
        }
    }

    function checkManagedValidatorAllowAllSignaturesRoles(
        address[] memory users,
        address[] memory allowedUsers,
        ManagedValidator validator,
        uint256 roleSet
    ) public view {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 roleSet_ = validator.allowAllSignaturesRoles(users[i]);
            if (has(allowedUsers, users[i])) {
                assertEq(roleSet_, roleSet, "Role check failed");
            } else {
                assertEq((roleSet_ & roleSet), 0, "Role check failed");
            }
        }
    }

    function checkManagedValidatorAllowSignatureRoles(
        address[] memory users,
        address[] memory allowedUsers,
        ManagedValidator validator,
        uint256 roleSet,
        bytes4 signature
    ) public view {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 roleSet_ = validator.allowSignatureRoles(
                users[i],
                signature
            );
            if (has(allowedUsers, users[i])) {
                assertEq(roleSet_, roleSet, "Role check failed");
            } else {
                assertEq((roleSet_ & roleSet), 0, "Role check failed");
            }
        }
    }

    function checkManagedValidatorCustomValidators(
        address[] memory users,
        ManagedValidator validator
    ) public view {
        for (uint256 i = 0; i < users.length; i++) {
            address customValidator = validator.customValidator(users[i]);
            assertEq(
                customValidator,
                address(0),
                "Custom validator check failed"
            );
        }
    }

    function makeUnique(address[] memory a) public pure {
        for (uint256 i = 0; i < a.length; i++)
            for (uint256 j = i + 1; j < a.length; j++)
                if (a[i] > a[j]) (a[i], a[j]) = (a[j], a[i]);
        uint256 itr = 0;
        for (uint256 i = 0; i < a.length; i++) {
            if (i == 0 || a[i] != a[i - 1]) {
                a[itr++] = a[i];
            }
        }
        assembly {
            mstore(a, itr)
        }
    }
}
