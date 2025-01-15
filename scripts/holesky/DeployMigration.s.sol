// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../src/migrators/HoleskyOmniDeployer.sol";
import {DeployConstants as Const} from "./DeployConstants.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast(uint256(bytes32(vm.envBytes("HOLESKY_DEPLOYER"))));

        uint256 balance = gasleft();
        HoleskyOmniDeployer deployer = new HoleskyOmniDeployer();
        console2.log(address(deployer), balance - gasleft());

        DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
            .DeployParameters({
                deployer: address(deployer),
                proxyAdmin: Const.MELLOW_LIDO_TEST_PROXY_MULTISIG,
                admin: Const.MELLOW_LIDO_TEST_MULTISIG,
                curator: Const.STEAKHOUSE_MULTISIG,
                wstethDefaultBondFactory: Const.WSTETH_DEFAULT_BOND_FACTORY,
                wstethDefaultBond: Const.WSTETH_DEFAULT_BOND,
                wsteth: Const.WSTETH,
                steth: Const.STETH,
                weth: Const.WETH,
                maximalTotalSupply: Const.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: Const.STEAKHOUSE_VAULT_TEST_NAME,
                lpTokenSymbol: Const.STEAKHOUSE_VAULT_TEST_SYMBOL,
                initialDepositETH: Const.INITIAL_DEPOSIT_ETH,
                firstDepositETH: Const.FIRST_DEPOSIT_ETH,
                initialImplementation: Vault(
                    payable(address(0x1F221aad7b77d95042cf535bfB070c9722A34CF5))
                ),
                initializer: Initializer(
                    address(0x6B92d88f4cd4728b9cd072C7b85bC485f6c56207)
                ),
                erc20TvlModule: ERC20TvlModule(
                    address(0xc7dc1D541243E38CE817E800ee05764F878c91a3)
                ),
                defaultBondTvlModule: DefaultBondTvlModule(
                    address(0x5d6A4E700c5D1707Dc0163ec81c7Ef71710a88eF)
                ),
                defaultBondModule: DefaultBondModule(
                    address(0x57Cf4E0Dbc71aEa67bFcb4bc3f8857e93558A72c)
                ),
                ratiosOracle: ManagedRatiosOracle(
                    address(0x7b6287Ca1d1eA6916D3d630fC4A267497df81033)
                ),
                priceOracle: ChainlinkOracle(
                    address(0xE7b4356A9aB0558Dcc6B14E4f577daa7544351F8)
                ),
                wethAggregatorV3: IAggregatorV3(
                    address(0x89f08EcB1B39012256634edc58a464835cF67825)
                ),
                wstethAggregatorV3: IAggregatorV3(
                    address(0x7e79BCc1A792384c1D12EcEcB3107E6a6C836413)
                ),
                defaultProxyImplementation: DefaultProxyImplementation(
                    address(0x4A78dB7944F53997807bEB572d90fc3328982805)
                )
            });

        DeployInterfaces.DeploySetup memory setup;
        (deployParams, setup) = deployer.deploy{
            value: deployParams.initialDepositETH
        }(
            deployParams,
            bytes32(0),
            address(0xadB08D2C53D4C47Db0f780B835bA19e71BC19787)
        );

        if (address(setup.proxyAdmin) == address(0)) {
            console2.log(
                "ProxyAdmin:",
                address(
                    uint160(
                        uint256(
                            vm.load(
                                address(setup.vault),
                                ERC1967Utils.ADMIN_SLOT
                            )
                        )
                    )
                )
            );
            revert("proxy admin");
        }

        console2.log(address(deployer), balance - gasleft());

        vm.stopBroadcast();

        logSetup(setup);
        logDeployParams(deployParams);

        revert("Success");
    }

    function logSetup(DeployInterfaces.DeploySetup memory setup) internal view {
        console2.log(IERC20Metadata(address(setup.vault)).name());
        console2.log("Vault: ", address(setup.vault));
        console2.log("Configurator: ", address(setup.configurator));
        console2.log("Validator: ", address(setup.validator));
        console2.log(
            "DefaultBondStrategy: ",
            address(setup.defaultBondStrategy)
        );
        console2.log("DepositWrapper: ", address(setup.depositWrapper));
        console2.log("WstethAmountDeposited: ", setup.wstethAmountDeposited);
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
        console2.log("Curator: ", address(deployParams.curator));
        console2.log(
            "WstethDefaultBondFactory: ",
            address(deployParams.wstethDefaultBondFactory)
        );
        console2.log(
            "WstethDefaultBond: ",
            address(deployParams.wstethDefaultBond)
        );
        console2.log("Wsteth: ", address(deployParams.wsteth));
        console2.log("Steth: ", address(deployParams.steth));
        console2.log("Weth: ", address(deployParams.weth));
        console2.log("MaximalTotalSupply: ", deployParams.maximalTotalSupply);
        console2.log("LpTokenName: ", deployParams.lpTokenName);
        console2.log("LpTokenSymbol: ", deployParams.lpTokenSymbol);
        console2.log("InitialDepositETH: ", deployParams.initialDepositETH);
        console2.log("Initializer: ", address(deployParams.initializer));
        console2.log(
            "InitialImplementation: ",
            address(deployParams.initialImplementation)
        );
        console2.log("Erc20TvlModule: ", address(deployParams.erc20TvlModule));
        console2.log(
            "DefaultBondTvlModule: ",
            address(deployParams.defaultBondTvlModule)
        );
        console2.log(
            "DefaultBondModule: ",
            address(deployParams.defaultBondModule)
        );
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
