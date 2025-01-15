// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/Address.sol";

import "./HoleskyDeployer1.sol";
import "./HoleskyDeployer2.sol";

contract HoleskyOmniDeployer {
    HoleskyDeployer1 public immutable deployer1;
    HoleskyDeployer2 public immutable deployer2;

    constructor() {
        deployer1 = new HoleskyDeployer1();
        deployer2 = new HoleskyDeployer2();
    }

    function deploy(
        DeployInterfaces.DeployParameters memory deployParams,
        bytes32 salt,
        address expectedProxyAdmin
    )
        external
        payable
        returns (
            DeployInterfaces.DeployParameters memory,
            DeployInterfaces.DeploySetup memory s
        )
    {
        bytes memory data = Address.functionDelegateCall(
            address(deployer1),
            abi.encodeCall(
                deployer1.deploy,
                (deployParams, salt, expectedProxyAdmin)
            )
        );
        (deployParams, s) = abi.decode(
            data,
            (DeployInterfaces.DeployParameters, DeployInterfaces.DeploySetup)
        );

        if (address(s.proxyAdmin) == address(0)) {
            return (deployParams, s);
        }

        data = Address.functionDelegateCall(
            address(deployer2),
            abi.encodeCall(deployer2.deploy, (deployParams, s))
        );

        return
            abi.decode(
                data,
                (
                    DeployInterfaces.DeployParameters,
                    DeployInterfaces.DeploySetup
                )
            );
    }
}
