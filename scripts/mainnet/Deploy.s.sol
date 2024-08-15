// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";
import "./Validator.sol";
import "./EventValidator.sol";

contract Deploy is Script, DeployScript, Validator, EventValidator {
    function run() external {
        uint256 n = 2;
        address[] memory curators = new address[](n);
        curators[0] = DeployConstants.Quasar_WSTETH_MULTISIG;
        curators[1] = DeployConstants.Bedrock_MULTISIG;

        string[] memory names = new string[](n);
        names[0] = DeployConstants.Quasar_VAULT_NAME;
        names[1] = DeployConstants.Bedrock_VAULT_NAME;

        string[] memory symbols = new string[](n);
        symbols[0] = DeployConstants.Quasar_VAULT_SYMBOL;
        symbols[1] = DeployConstants.Bedrock_VAULT_SYMBOL;

        uint256 maximalTotalSupplies = new string[](n);
        maximalTotalSupplies[0] = DeployConstants.MAXIMAL_TOTAL_SUPPLY_QUASAR;
        maximalTotalSupplies[1] = DeployConstants.MAXIMAL_TOTAL_SUPPLY_BEDROCK;

        DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                proxyAdmin: DeployConstants.MELLOW_WSTETH_PROXY_MULTISIG,
                admin: DeployConstants.MELLOW_WSTETH_MULTISIG,
                curator: address(0),
                lpTokenName: "",
                lpTokenSymbol: "",
                wstethDefaultBond: DeployConstants.WSTETH_DEFAULT_BOND,
                wstethDefaultBondFactory: DeployConstants
                    .WSTETH_DEFAULT_BOND_FACTORY,
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: 0,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_ETH,
                firstDepositETH: DeployConstants.FIRST_DEPOSIT_ETH,
                initializer: Initializer(
                    address(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c)
                ),
                initialImplementation: Vault(
                    payable(address(0xaf108ae0AD8700ac41346aCb620e828c03BB8848))
                ),
                erc20TvlModule: ERC20TvlModule(
                    address(0x1EB0e946D7d757d7b085b779a146427e40ABBCf8)
                ),
                defaultBondTvlModule: DefaultBondTvlModule(
                    address(0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429)
                ),
                defaultBondModule: DefaultBondModule(
                    address(0xD8619769fed318714d362BfF01CA98ac938Bdf9b)
                ),
                ratiosOracle: ManagedRatiosOracle(
                    address(0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d)
                ),
                priceOracle: ChainlinkOracle(
                    address(0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d)
                ),
                wethAggregatorV3: IAggregatorV3(
                    address(0x6A8d8033de46c68956CCeBA28Ba1766437FF840F)
                ),
                wstethAggregatorV3: IAggregatorV3(
                    address(0x94336dF517036f2Bf5c620a1BC75a73A37b7bb16)
                ),
                defaultProxyImplementation: DefaultProxyImplementation(
                    address(0x02BB349832c58E892a20178b9696e2b93A3a9b0f)
                )
            });

        DeployInterfaces.DeploySetup[]
            memory setups = new DeployInterfaces.DeploySetup[](n);
        vm.startBroadcast(uint256(bytes32(vm.envBytes("MAINNET_DEPLOYER"))));
        deployParams = commonContractsDeploy(deployParams);
        for (uint256 i = 0; i < n; i++) {
            deployParams.curator = curators[i];
            deployParams.lpTokenName = names[i];
            deployParams.lpTokenSymbol = symbols[i];
            deployParams.maximalTotalSupply = maximalTotalSupplies[i];

            vm.recordLogs();
            (deployParams, setups[i]) = deploy(deployParams);
            validateParameters(deployParams, setups[i], 0);
            validateEvents(deployParams, setups[i], vm.getRecordedLogs());
        }

        vm.stopBroadcast();
        for (uint256 i = 0; i < n; i++) {
            logSetup(setups[i]);
        }
        logDeployParams(deployParams);

        revert("success");
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
