// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./PermissionsRunner.sol";
import "../Deployments.sol";

contract PermissionsTest is PermissionsRunner, DeployScript, Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    DeployInterfaces.DeployParameters internal deployParams;
    DeployInterfaces.DeploySetup internal setup;

    function deploy() internal {
        deployParams = Deployments.deployParameters();
        deal(
            deployParams.weth,
            deployParams.deployer,
            deployParams.initialDepositWETH
        );

        vm.startPrank(deployParams.deployer);
        deployParams = commonContractsDeploy(deployParams);
        (deployParams, setup) = deploy(deployParams);
        vm.stopPrank();
    }

    EnumerableSet.AddressSet private allAddresses_;

    function testPermissions() external {
        vm.recordLogs();
        deploy();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            allAddresses_.add(logs[i].emitter);
            for (uint256 j = 0; j < logs[i].topics.length; j++) {
                allAddresses_.add(address(bytes20(logs[i].topics[j])));
                allAddresses_.add(address(uint160(uint256(logs[i].topics[j]))));
            }
            bytes memory data = logs[i].data;
            for (uint256 offset = 0; offset < data.length; offset++) {
                bytes32 word;
                assembly {
                    word := mload(add(data, add(32, offset)))
                }
                allAddresses_.add(address(bytes20(word)));
                allAddresses_.add(address(uint160(uint256(word))));
            }
        }

        validatePermissions(deployParams, setup, allAddresses_.values());
    }

    struct Data {
        address addr;
    }

    function parseLogs(
        address vault
    ) public view returns (address[] memory addresses) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/tests/obol/permissions/__collector_logs__/",
            Strings.toHexString(vault),
            ".json"
        );
        bytes memory data = vm.parseJson(vm.readFile(path));
        Data[] memory d = abi.decode(data, (Data[]));
        addresses = new address[](d.length);
        for (uint256 i = 0; i < d.length; i++) {
            addresses[i] = d[i].addr;
        }
    }

    function testPermissionsOnchain() external {
        Deployments.Deployment[] memory deployments = Deployments.deployments();

        if (deployments.length == 0) {
            console2.log(
                "No deployments found for chain id %d. Skipping...",
                block.chainid
            );
            return;
        }

        for (uint256 i = 0; i < deployments.length; i++) {
            deployParams = deployments[i].deployParams;
            setup = deployments[i].deploySetup;
            address[] memory addresses = parseLogs(address(setup.vault));
            validatePermissions(deployParams, setup, addresses);
        }
    }
}
