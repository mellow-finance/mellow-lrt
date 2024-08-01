// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./AcceptanceRunner.sol";
import "../Deployments.sol";

contract AcceptanceTest is AcceptanceRunner, DeployScript, Test {
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

    DeployInterfaces.DeployParameters private mainnetParams =
        DeployInterfaces.DeployParameters(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.MAINNET_PROXY_VAULT_ADMIN,
            DeployConstants.MAINNET_VAULT_ADMIN,
            DeployConstants.MAINNET_CURATOR_ADMIN,
            DeployConstants.MAINNET_CURATOR_OPERATOR,
            DeployConstants.MAINNET_LIDO_LOCATOR,
            DeployConstants.MAINNET_WSTETH,
            DeployConstants.MAINNET_STETH,
            DeployConstants.MAINNET_WETH,
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

    DeployInterfaces.DeployParameters internal deployParams;
    DeployInterfaces.DeploySetup internal setup;

    function deploy() internal {
        if (block.chainid == 1) {
            deployParams = mainnetParams;
        } else if (block.chainid == 17000) {
            deployParams = holeskyParams;
        } else {
            revert("Unsupported chain");
        }

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

    function testAcceptance() external {
        deploy();
        HAS_IN_DEPLOYMENT_BLOCK_FLAG = true;
        HAS_TEST_PARAMETERS = false;
        validateParameters(deployParams, setup);
    }

    function testAcceptanceOnTestingDeployment() external {
        Deployments.Deployment[] memory deployments;
        if (block.chainid == 1) {
            console2.log("No mainnet deployment yet. Skipping...");
            return;
        }

        if (block.chainid == 17000) {
            deployments = Deployments.deployments();
        } else {
            revert("Unsupported chain");
        }

        for (uint256 i = 0; i < deployments.length; i++) {
            deployParams = deployments[i].deployParams;
            setup = deployments[i].deploySetup;

            HAS_IN_DEPLOYMENT_BLOCK_FLAG = false;
            HAS_TEST_PARAMETERS = true;

            validateParameters(deployParams, setup);
        }
    }
}
