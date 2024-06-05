// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

abstract contract EventValidator is StdAssertions, CommonBase {
    bytes32 public constant OPERATOR = keccak256("operator");
    bytes32 public constant ADMIN_ROLE = keccak256("admin");
    bytes32 public constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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

        assertEq(e[3].emitter, address(setup.vault));
        assertEq(e[3].topics.length, 4);
        assertEq(e[3].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[3].topics[1], OPERATOR);
        assertEq(
            e[3].topics[2],
            bytes32(uint256(uint160(deployParams.deployer)))
        );
        assertEq(
            e[3].topics[3],
            bytes32(uint256(uint160(deployParams.deployer)))
        );
        assertEq(e[3].data, new bytes(0));

        assertEq(e[4].emitter, address(setup.vault));
        assertEq(e[4].topics.length, 4);
        assertEq(e[4].topics[0], IAccessControl.RoleGranted.selector);
        assertEq(e[4].topics[1], ADMIN_ROLE);
        assertEq(
            e[4].topics[2],
            bytes32(uint256(uint160(deployParams.deployer)))
        );
        assertEq(
            e[4].topics[3],
            bytes32(uint256(uint160(deployParams.deployer)))
        );
        assertEq(e[4].data, new bytes(0));

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

        assertTrue(false);
    }
}
