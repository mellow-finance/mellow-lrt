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

    function validateEvents(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup,
        Vm.Log[] memory e
    ) public {
        assertEq(e.length, 111);

        assertEq(e[0].emitter, address(setup.vault));
        assertEq(e[0].topics.length, 2);
        assertEq(e[0].topics[0], ERC1967Utils.Upgraded.selector);
        assertEq(
            e[0].topics[1],
            bytes32(uint256(uint160(address(deployParams.initializer))))
        );
        assertEq(e[0].data, new bytes(0));

        assertEq(e[1].emitter, address(setup.proxyAdmin));
        assertEq(e[1].topics.length, 3);
        assertEq(e[1].topics[0], Ownable.OwnershipTransferred.selector);
        assertEq(e[1].topics[1], bytes32(uint256(uint160(address(0)))));
        assertEq(
            e[1].topics[2],
            bytes32(uint256(uint160(address(deployParams.deployer))))
        );
        assertEq(e[1].data, new bytes(0));

        assertEq(e[2].emitter, address(setup.vault));
        assertEq(e[2].topics.length, 1);
        assertEq(e[2].topics[0], ERC1967Utils.AdminChanged.selector);
        assertEq(e[2].data, abi.encode(address(0), address(setup.proxyAdmin)));

        validateRoleGrantedEvent(e[3], address(setup.vault), OPERATOR, deployParams.deployer, deployParams.deployer);
        validateRoleGrantedEvent(e[4], address(setup.vault), ADMIN_ROLE, deployParams.deployer, deployParams.deployer);

        assertEq(e[5].emitter, address(setup.vault));
        assertEq(e[5].topics.length, 4);
        assertEq(e[5].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[5].topics[1], ADMIN_ROLE);
        assertEq(e[5].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[5].topics[3], ADMIN_ROLE);
        assertEq(e[5].data, new bytes(0));

        assertEq(e[6].emitter, address(setup.vault));
        assertEq(e[6].topics.length, 4);
        assertEq(e[6].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[6].topics[1], ADMIN_DELEGATE_ROLE);
        assertEq(e[6].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[6].topics[3], ADMIN_ROLE);
        assertEq(e[6].data, new bytes(0));

        assertEq(e[7].emitter, address(setup.vault));
        assertEq(e[7].topics.length, 4);
        assertEq(e[7].topics[0], IAccessControl.RoleAdminChanged.selector);
        assertEq(e[7].topics[1], OPERATOR);
        assertEq(e[7].topics[2], DEFAULT_ADMIN_ROLE);
        assertEq(e[7].topics[3], ADMIN_DELEGATE_ROLE);
        assertEq(e[7].data, new bytes(0));

        assertEq(e[8].emitter, address(setup.vault));
        assertEq(e[8].topics.length, 2);
        assertEq(e[8].topics[0], ERC1967Utils.Upgraded.selector);
        assertEq(
            e[8].topics[1],
            bytes32(
                uint256(uint160(address(deployParams.initialImplementation)))
            )
        );
        assertEq(e[8].data, new bytes(0));
        
        assertEq(e[9].emitter, address(setup.proxyAdmin));
        assertEq(e[9].topics.length, 3);
        assertEq(e[9].topics[0], Ownable.OwnershipTransferred.selector);
        assertEq(e[9].topics[1], bytes32(uint256(uint160(address(deployParams.deployer)))));
        assertEq(
            e[9].topics[2],
            bytes32(uint256(uint160(address(deployParams.proxyAdmin))))
        );
        assertEq(e[9].data, new bytes(0));

        validateRoleGrantedEvent(e[10], address(setup.timeLockedCurator), DEFAULT_ADMIN_ROLE, address(setup.timeLockedCurator), deployParams.deployer);       
        validateRoleGrantedEvent(e[11], address(setup.timeLockedCurator), DEFAULT_ADMIN_ROLE, address(deployParams.admin), deployParams.deployer);
        validateRoleGrantedEvent(e[12], address(setup.timeLockedCurator), PROPOSER_ROLE, address(deployParams.curator), deployParams.deployer);
        validateRoleGrantedEvent(e[13], address(setup.timeLockedCurator), CANCELLER_ROLE, address(deployParams.curator), deployParams.deployer);
        validateRoleGrantedEvent(e[14], address(setup.timeLockedCurator), PROPOSER_ROLE, address(deployParams.admin), deployParams.deployer);
        validateRoleGrantedEvent(e[15], address(setup.timeLockedCurator), CANCELLER_ROLE, address(deployParams.admin), deployParams.deployer);
        validateRoleGrantedEvent(e[16], address(setup.timeLockedCurator), EXECUTOR_ROLE, address(deployParams.curator), deployParams.deployer);
        validateRoleGrantedEvent(e[17], address(setup.timeLockedCurator), EXECUTOR_ROLE, address(deployParams.admin), deployParams.deployer);

        assertEq(e[18].emitter, address(setup.timeLockedCurator));
        assertEq(e[18].topics.length, 1);
        assertEq(e[18].topics[0], TimelockController.MinDelayChange.selector);
        assertEq(e[18].data, abi.encode(uint256(0), uint256(60)));
        
        
        validateRoleGrantedEvent(e[19], address(setup.vault), ADMIN_DELEGATE_ROLE, address(deployParams.deployer), deployParams.deployer);
        validateRoleGrantedEvent(e[20], address(setup.vault), ADMIN_ROLE, address(deployParams.admin), deployParams.deployer);
        validateRoleGrantedEvent(e[21], address(setup.vault), ADMIN_DELEGATE_ROLE, address(setup.timeLockedCurator), deployParams.deployer);
        
        assertEq(e[22].emitter, address(setup.vault));
        assertEq(e[22].topics.length, 1);
        assertEq(e[22].topics[0], IVault.TvlModuleAdded.selector);
        assertEq(e[22].data, abi.encode(address(deployParams.erc20TvlModule)));

        assertEq(e[23].emitter, address(setup.vault));
        assertEq(e[23].topics.length, 1);
        assertEq(e[23].topics[0], IVault.TvlModuleAdded.selector);
        assertEq(e[23].data, abi.encode(address(deployParams.defaultBondTvlModule)));

        assertEq(e[24].emitter, address(setup.vault));
        assertEq(e[24].topics.length, 1);
        assertEq(e[24].topics[0], IVault.TokenAdded.selector);
        assertEq(e[24].data, abi.encode(deployParams.wsteth));
        {
            uint256[] memory depositWithdrawalRatiosX96 = new uint256[](1);
            depositWithdrawalRatiosX96[0] = 2 ** 96;

            assertEq(e[25].emitter, address(deployParams.ratiosOracle));
            assertEq(e[25].topics.length, 2);
            assertEq(e[25].topics[0], IManagedRatiosOracle.ManagedRatiosOracleUpdateRatios.selector);
            assertEq(e[25].topics[1], bytes32(uint256(uint160(address(setup.vault)))));
            assertEq(e[25].data, abi.encode(true, depositWithdrawalRatiosX96));

            assertEq(e[26].emitter, address(deployParams.ratiosOracle));
            assertEq(e[26].topics.length, 2);
            assertEq(e[26].topics[0], IManagedRatiosOracle.ManagedRatiosOracleUpdateRatios.selector);
            assertEq(e[26].topics[1], bytes32(uint256(uint160(address(setup.vault)))));
            assertEq(e[26].data, abi.encode(false, depositWithdrawalRatiosX96));
        }

        assertTrue(false, "Success");
    }

    function validateRoleGrantedEvent(Vm.Log memory e, address emitter, bytes32 role, address account, address sender) public {
        assertEq(e.emitter, emitter);
        assertEq(e.topics.length, 4);
        assertEq(e.topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e.topics[1], role);
        assertEq(e.topics[2], bytes32(uint256(uint160(account))));
        assertEq(e.topics[3], bytes32(uint256(uint160(sender))));
        assertEq(e.data, new bytes(0));
    }
}
