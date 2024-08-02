// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";

import {Deployments} from "../../tests/obol/Deployments.sol";

import {AcceptanceRunner} from "../../tests/obol/acceptance/AcceptanceRunner.sol";
import {PermissionsRunner} from "../../tests/obol/permissions/PermissionsRunner.sol";

contract Deploy is Script, DeployScript, AcceptanceRunner, PermissionsRunner {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private allAddresses_;

    function run() external {
        DeployInterfaces.DeployParameters memory deployParams = Deployments
            .deployParameters();

        vm.startBroadcast(uint256(bytes32(vm.envBytes("MAINNET_DEPLOYER"))));
        deployParams = commonContractsDeploy(deployParams);
        DeployInterfaces.DeploySetup memory setup;

        vm.recordLogs();
        IWeth(deployParams.weth).deposit{
            value: deployParams.initialDepositWETH
        }();
        (deployParams, setup) = deploy(deployParams);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        vm.stopBroadcast();

        logSetup(setup);
        logDeployParams(deployParams);

        HAS_IN_DEPLOYMENT_BLOCK_FLAG = true;
        HAS_TEST_PARAMETERS = false;

        validateParameters(deployParams, setup);
        {
            for (uint256 i = 0; i < logs.length; i++) {
                allAddresses_.add(logs[i].emitter);
                for (uint256 j = 0; j < logs[i].topics.length; j++) {
                    allAddresses_.add(address(bytes20(logs[i].topics[j])));
                    allAddresses_.add(
                        address(uint160(uint256(logs[i].topics[j])))
                    );
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
        revert("success");
    }

    function logSetup(DeployInterfaces.DeploySetup memory setup) internal view {
        console2.log(IERC20Metadata(address(setup.vault)).name());
        console2.log("Vault: ", address(setup.vault));
        console2.log("Configurator: ", address(setup.configurator));
        console2.log("Validator: ", address(setup.validator));
        console2.log("SimpleDVTStakingStrategy: ", address(setup.strategy));
        console2.log(
            "TransparentUpgradeableProxy-ProxyAdmin: ",
            address(setup.proxyAdmin)
        );
        console2.log("---------------------------");
        block.timestamp;
    }

    function logDeployParams(
        DeployInterfaces.DeployParameters memory deployParams
    ) internal view {
        console2.log("Deployer: ", address(deployParams.deployer));
        console2.log("ProxyAdmin: ", address(deployParams.proxyAdmin));
        console2.log("Admin: ", address(deployParams.admin));
        console2.log("Curator admin: ", address(deployParams.curatorAdmin));
        console2.log(
            "Curator operator: ",
            address(deployParams.curatorOperator)
        );
        console2.log("LidoLocator: ", address(deployParams.lidoLocator));
        console2.log("Wsteth: ", address(deployParams.wsteth));
        console2.log("Steth: ", address(deployParams.steth));
        console2.log("Weth: ", address(deployParams.weth));
        console2.log("MaximalTotalSupply: ", deployParams.maximalTotalSupply);
        console2.log("LpTokenName: ", deployParams.lpTokenName);
        console2.log("LpTokenSymbol: ", deployParams.lpTokenSymbol);
        console2.log("initialDepositWETH: ", deployParams.initialDepositWETH);
        console2.log("Initializer: ", address(deployParams.initializer));
        console2.log(
            "InitialImplementation: ",
            address(deployParams.initialImplementation)
        );
        console2.log("Erc20TvlModule: ", address(deployParams.erc20TvlModule));
        console2.log("StakingModule: ", address(deployParams.stakingModule));
        console2.log("RatiosOracle: ", address(deployParams.ratiosOracle));
        console2.log("PriceOracle: ", address(deployParams.priceOracle));
        console2.log(
            "WethAggregatorV3: ",
            address(deployParams.wethAggregatorV3)
        );
        console2.log(
            "WstethAggregatorV3: ",
            address(deployParams.wstethAggregatorV3)
        );
        console2.log(
            "DefaultProxyImplementation: ",
            address(deployParams.defaultProxyImplementation)
        );
        block.timestamp;
    }
}
