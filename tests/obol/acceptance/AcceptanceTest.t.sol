// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./AcceptanceRunner.sol";

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
        HAS_EXTRA_STRATEGY_ADMIN_DELEGATE = false;
        validateParameters(deployParams, setup);
    }

    function testAcceptanceOnTestingDeployment() external {
        if (block.chainid == 1) {
            console2.log("No mainnet deployment yet. Skipping...");
            return;
        } else if (block.chainid == 17000) {
            deployParams = DeployInterfaces.DeployParameters(
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
                Vault(payable(0x1EF5eaB67AE611092b8003D42cA684bD4C196fFc)),
                Initializer(0x279F68f4a9b5dB11fC32B04Cb4F56794fad48242),
                ERC20TvlModule(0x0e4701020700f53b0a8903D7a3A6209Ae97a1BC0),
                StakingModule(0x3B342b4BA8cc065C6b115A18dbcf1c2B54FC93E2),
                ManagedRatiosOracle(0x64e70C5B72412efe67Ea4872BfCb80570aC5e93f),
                ChainlinkOracle(0x7C76B8411e0C530F6aa86858d1B12d6e62845bc6),
                IAggregatorV3(0x329eA0287b8198C59FD8D89D8F2bb0316Bd35d67),
                IAggregatorV3(0xA1CF7999E6Befe221581E3F74AAd442E88618ca0),
                DefaultProxyImplementation(0x202aeBF79bC49f39F4e6E72973f48c361349e9D6)
            );
            setup = DeployInterfaces.DeploySetup({
                vault: Vault(payable(0x2d3086B7d3A2A14e121c0Fce651F9E1A819A1E84)),
                proxyAdmin: ProxyAdmin(0x7594059ABEd2Fb1B1dA8715282AaD7e52Afd16c8),
                configurator: IVaultConfigurator(0xa81e199E01350e7d7EE6bE846329b20e43eee735),
                validator: ManagedValidator(0xE659ab3De7Ca8F6ac4D52a0b7cE0DcaAbD07946A),
                strategy: SimpleDVTStakingStrategy(0x1911D3D13a91561E8bc16182E1ec6A1E612f8E9e)
            });
        } else {
            revert("Unsupported chain");
        }
        
        HAS_IN_DEPLOYMENT_BLOCK_FLAG = false;
        HAS_EXTRA_STRATEGY_ADMIN_DELEGATE = true;

        validateParameters(deployParams, setup);
    }
}
