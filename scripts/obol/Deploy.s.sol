// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";

contract Deploy is Script, DeployScript {
    DeployInterfaces.DeployParameters private holeskyParams =
        DeployInterfaces.DeployParameters(
            DeployConstants.HOLESKY_DEPLOYER,
            DeployConstants.HOLESKY_PROXY_VAULT_ADMIN,
            DeployConstants.HOLESKY_VAULT_ADMIN,
            DeployConstants.HOLESKY_CURATOR_ADMIN,
            DeployConstants.HOLESKY_CURATOR_OPERATOR,
            DeployConstants.HOLESKY_LIDO_LOCATOR,
            DeployConstants.HOLESKY_WSTETH,
            DeployConstants.HOLESKY_STETH,
            DeployConstants.HOLESKY_WETH,
            DeployConstants.MAXIMAL_TOTAL_SUPPLY,
            DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
            DeployConstants.MELLOW_VAULT_NAME,
            DeployConstants.MELLOW_VAULT_SYMBOL,
            DeployConstants.INITIAL_DEPOSIT_ETH,
            Vault(payable(address(0))),
            Initializer(address(0)),
            ERC20TvlModule(address(0)),
            StakingModule(address(0)),
            ManagedRatiosOracle(address(0)),
            ChainlinkOracle(address(0)),
            IAggregatorV3(address(0)),
            IAggregatorV3(address(0)),
            DefaultProxyImplementation(address(0))
        );

    function run() external {
        DeployInterfaces.DeployParameters memory deployParams = holeskyParams;
        vm.startBroadcast(uint256(bytes32(vm.envBytes("HOLESKY_DEPLOYER"))));
        deployParams = commonContractsDeploy(deployParams);
        DeployInterfaces.DeploySetup memory setup;
        (deployParams, setup) = deploy(deployParams);
        vm.stopBroadcast();
        logSetup(setup);
        logDeployParams(deployParams);
        // revert("success");
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
