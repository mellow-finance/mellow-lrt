// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./ValidationLibrary.sol";

import "./DeployConstantsProd.sol";

contract AcceptanceTest is DeployScript {
    address public immutable wstethDefaultBond =
        address(new DefaultBondMock(DeployConstants.WSTETH));
/* 
    function testDeployWithValidationSteakhouseFinancial() external {
        deal(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
        );
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                admin: DeployConstants.STEAKHOUSE_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.STEAKHOUSE_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.STEAKHOUSE_CURATOR_MANAGER,
                proposer: DeployConstants.STEAKHOUSE_MELLOW_MULTISIG,
                acceptor: DeployConstants.STEAKHOUSE_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.STEAKHOUSE_MELLOW_MULTISIG,
                wstethDefaultBond: wstethDefaultBond, // to be deployed
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.STEAKHOUSE_VAULT_NAME,
                lpTokenSymbol: DeployConstants.STEAKHOUSE_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    }
 */
    function testDeployWithValidationRe7Labs() external {
        deal(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
        );
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstantsProd.MAINNET_DEPLOYER,
                admin: DeployConstantsProd.RE7_CURATOR_BOARD_MULTISIG,
                curator: DeployConstantsProd.RE7_CURATOR_BOARD_MULTISIG,
                operator: DeployConstantsProd.RE7_CURATOR_MANAGER,
                proposer: DeployConstantsProd.RE7_MELLOW_MULTISIG,
                acceptor: DeployConstantsProd.RE7_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstantsProd.RE7_MELLOW_MULTISIG,
                wstethDefaultBond: wstethDefaultBond, // to be deployed
                wsteth: DeployConstantsProd.WSTETH,
                steth: DeployConstantsProd.STETH,
                weth: DeployConstantsProd.WETH,
                maximalTotalSupply: DeployConstantsProd.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstantsProd.RE7_VAULT_NAME,
                lpTokenSymbol: DeployConstantsProd.RE7_VAULT_SYMBOL,
                initialDepositETH: DeployConstantsProd.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory setup;// = deploy(deployParams);

        setup.initializer = Initializer(DeployConstantsProd.RE7_VAULT_INITIALIZER);
        setup.vault = Vault(DeployConstantsProd.RE7_VAULT_ADDRESS);
        setup.initialImplementation = Vault(DeployConstantsProd.RE7_VAULT_ADDRESS_INIT);
        setup.configurator = IVaultConfigurator(DeployConstantsProd.RE7_VAULT_CONFIGURATOR);
        setup.erc20TvlModule = ERC20TvlModule(DeployConstantsProd.RE7_VAULT_ERC20TVLMODULE);
        setup.defaultBondTvlModule = DefaultBondTvlModule(DeployConstantsProd.RE7_VAULT_DEFAULTBONDTVLMODULE);
        setup.defaultBondModule = DefaultBondModule(DeployConstantsProd.RE7_VAULT_DEFAULTBONDMODULE);
        setup.validator = ManagedValidator(DeployConstantsProd.RE7_VAULT_MANAGED_VALIDATOR);
        setup.ratiosOracle = ManagedRatiosOracle(DeployConstantsProd.RE7_VAULT_RATIOS_ORACLE);
        setup.priceOracle = ChainlinkOracle(DeployConstantsProd.RE7_VAULT_PRICE_ORACLE);
        setup.defaultBondStrategy = DefaultBondStrategy(DeployConstantsProd.RE7_VAULT_DEFAULTBONDMODULE);
        setup.depositWrapper = DepositWrapper(DeployConstantsProd.RE7_VAULT_DEPOSIT_WRAPPER);
        setup.defaultProxyImplementation = DefaultProxyImplementation(DeployConstantsProd.RE7_VAULT_DEFAULT_PROXY_IMPLEMENTATION);
        setup.adminProxy = AdminProxy(DeployConstantsProd.RE7_VAULT_ADMIN_PROXY);
        //setup.//RestrictingKeeper restrictingKeeper;
        setup.wethAggregatorV3 = IAggregatorV3(DeployConstantsProd.RE7_VAULT_WETH_AGGREGATOR);
        setup.wstethAggregatorV3 = IAggregatorV3(DeployConstantsProd.RE7_VAULT_WSTETH_AGGREGATOR);
        setup.wstethAmountDeposited = DeployConstantsProd.RE7_VAULT_WETH_AMOUNT_DEPOSITED;

        ValidationLibrary.validateParameters(deployParams, setup);
    }
/* 
    function testDeployWithValidationP2P() external {
        deal(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
        );
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                admin: DeployConstants.P2P_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.P2P_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.P2P_CURATOR_MANAGER,
                proposer: DeployConstants.P2P_MELLOW_MULTISIG,
                acceptor: DeployConstants.P2P_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.P2P_MELLOW_MULTISIG,
                wstethDefaultBond: wstethDefaultBond, // to be deployed
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.P2P_VAULT_NAME,
                lpTokenSymbol: DeployConstants.P2P_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    } */
}
