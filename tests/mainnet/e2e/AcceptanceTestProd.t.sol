// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "../../../scripts/mainnet/Validator.sol";
//import "./ValidationLibrary.sol";

import "./DeployConstantsProd.sol";

contract AcceptanceTest is DeployScript {
    address public immutable wstethDefaultBond =
        address(new DefaultBondMock(DeployConstantsProd.WSTETH));
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
        /*  deal(
            DeployConstantsProd.MAINNET_DEPLOYER,
            DeployConstantsProd.INITIAL_DEPOSIT_VALUE
        ); */
        DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
            .DeployParameters({
                deployer: DeployConstantsProd.MAINNET_DEPLOYER,
                proxyAdmin: DeployConstantsProd.RE7_VAULT_ADMIN_PROXY,
                admin: DeployConstantsProd.RE7_CURATOR_BOARD_MULTISIG,
                curator: DeployConstantsProd.RE7_CURATOR_BOARD_MULTISIG,
                wstethDefaultBondFactory: DeployConstantsProd
                    .RE7_VAULT_WETH_DEFAULT_BOND_FACTORY,
                wstethDefaultBond: DeployConstantsProd
                    .RE7_VAULT_WETH_DEFAULT_BOND,
                wsteth: DeployConstantsProd.WSTETH,
                steth: DeployConstantsProd.STETH,
                weth: DeployConstantsProd.WETH,
                maximalTotalSupply: 10000000000000000000000,
                lpTokenName: DeployConstantsProd.RE7_VAULT_NAME,
                lpTokenSymbol: DeployConstantsProd.RE7_VAULT_SYMBOL,
                initialDepositETH: DeployConstantsProd
                    .RE7_VAULT_WETH_AMOUNT_DEPOSITED,
                firstDepositETH: DeployConstantsProd
                    .RE7_VAULT_WETH_AMOUNT_DEPOSITED,
                initialImplementation: Vault(
                    DeployConstantsProd.RE7_VAULT_ADDRESS_INIT
                ),
                initializer: Initializer(
                    DeployConstantsProd.RE7_VAULT_INITIALIZER
                ),
                erc20TvlModule: ERC20TvlModule(
                    DeployConstantsProd.RE7_VAULT_ERC20TVLMODULE
                ),
                defaultBondTvlModule: DefaultBondTvlModule(
                    DeployConstantsProd.RE7_VAULT_DEFAULTBONDTVLMODULE
                ),
                defaultBondModule: DefaultBondModule(
                    DeployConstantsProd.RE7_VAULT_DEFAULTBONDMODULE
                ),
                ratiosOracle: ManagedRatiosOracle(
                    DeployConstantsProd.RE7_VAULT_RATIOS_ORACLE
                ),
                priceOracle: ChainlinkOracle(
                    DeployConstantsProd.RE7_VAULT_PRICE_ORACLE
                ),
                wethAggregatorV3: IAggregatorV3(
                    DeployConstantsProd.RE7_VAULT_WETH_AGGREGATOR
                ),
                wstethAggregatorV3: IAggregatorV3(
                    DeployConstantsProd.RE7_VAULT_WSTETH_AGGREGATOR
                ),
                defaultProxyImplementation: DefaultProxyImplementation(
                    DeployConstantsProd.RE7_VAULT_DEFAULT_PROXY_IMPLEMENTATION
                )
            });
        DeployInterfaces.DeploySetup memory setup; // = deploy(deployParams);

        setup.vault = Vault(DeployConstantsProd.RE7_VAULT_ADDRESS);
        setup.configurator = IVaultConfigurator(
            DeployConstantsProd.RE7_VAULT_CONFIGURATOR
        );
        setup.validator = ManagedValidator(
            DeployConstantsProd.RE7_VAULT_MANAGED_VALIDATOR
        );
        setup.defaultBondStrategy = DefaultBondStrategy(
            DeployConstantsProd.RE7_VAULT_DEFAULTBONDMODULE
        );
        setup.depositWrapper = DepositWrapper(
            DeployConstantsProd.RE7_VAULT_DEPOSIT_WRAPPER
        );
        setup.wstethAmountDeposited = DeployConstantsProd
            .RE7_VAULT_WETH_AMOUNT_DEPOSITED;

        // Validator validator = new Validator();

        // validator.validateParameters(deployParams, setup);
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
