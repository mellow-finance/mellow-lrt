// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";
import "./Validator.sol";

contract Deploy is Script, DeployScript, Validator {
    function run() external {
        DeployInterfaces.DeployParameters memory deployParams;

        bool test = false;
        uint256 n = 4;

        address[] memory curators = new address[](n);
        curators[0] = DeployConstants.STEAKHOUSE_MULTISIG;
        curators[1] = DeployConstants.RE7_MULTISIG;
        curators[2] = DeployConstants.MEV_MULTISIG;
        curators[3] = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        string[] memory names = new string[](n);
        names[0] = DeployConstants.STEAKHOUSE_VAULT_TEST_NAME;
        names[1] = DeployConstants.RE7_VAULT_TEST_NAME;
        names[2] = DeployConstants.MEV_VAULT_TEST_NAME;
        names[3] = DeployConstants.MELLOW_VAULT_NAME;

        string[] memory symbols = new string[](n);
        symbols[0] = DeployConstants.STEAKHOUSE_VAULT_TEST_SYMBOL;
        symbols[1] = DeployConstants.RE7_VAULT_TEST_SYMBOL;
        symbols[2] = DeployConstants.MEV_VAULT_TEST_SYMBOL;
        symbols[3] = DeployConstants.MELLOW_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.HOLESKY_TEST_DEPLOYER;
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("HOLESKY_TEST_DEPLOYER")))
        );

        deployParams.proxyAdmin = DeployConstants
            .MELLOW_LIDO_TEST_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        // only for testing purposes
        if (test) {
            TransparentUpgradeableProxy factory = new TransparentUpgradeableProxy(
                    DeployConstants.WSTETH_DEFAULT_BOND_FACTORY,
                    address(this),
                    ""
                );
            deployParams.wstethDefaultBond = IDefaultCollateralFactory(
                address(factory)
            ).create(DeployConstants.WSTETH, type(uint256).max, address(0));
            deployParams.wstethDefaultBondFactory = address(factory);
        } else {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY;
        }

        deployParams.wsteth = DeployConstants.WSTETH;
        deployParams.steth = DeployConstants.STETH;
        deployParams.weth = DeployConstants.WETH;

        deployParams.maximalTotalSupply = DeployConstants.MAXIMAL_TOTAL_SUPPLY;
        deployParams.initialDepositETH = DeployConstants.INITIAL_DEPOSIT_ETH;
        deployParams.firstDepositETH = DeployConstants.FIRST_DEPOSIT_ETH;
        deployParams.timeLockDelay = DeployConstants.TIMELOCK_TEST_DELAY;

        DeployInterfaces.DeploySetup[]
            memory setups = new DeployInterfaces.DeploySetup[](n);

        if (true) {
            deployParams.initializer = Initializer(
                0xDA60A9DBAF70d0e3114117eCf6F1cCB570FBD6f8
            );
            deployParams.initialImplementation = Vault(
                payable(0xE3CaF6904164621d5F30BE24B7f17A3B07F50C4E)
            );
            // deployParams.configurator = VaultConfigurator(0x7cC601500E990f6287E12074628E2577e7D1b6ca);
            deployParams.erc20TvlModule = ERC20TvlModule(
                0xF18111AD540712615494Ef056107a6C28aa33dcb
            );
            deployParams.defaultBondModule = DefaultBondModule(
                0x634dBBf252938a0b4311DC9ba384dA250E078807
            );
            deployParams.defaultBondTvlModule = DefaultBondTvlModule(
                0xB1A10B4021020D0963D3320071AdF2D874E97d34
            );
            deployParams.ratiosOracle = ManagedRatiosOracle(
                0xdE2A9f40F989C34399BA5B3D1af3279629c6aCF5
            );
            deployParams.priceOracle = ChainlinkOracle(
                0xA83B506542701557e048901e7AF8D65439Ed9C75
            );
            deployParams.wethAggregatorV3 = ConstantAggregatorV3(
                0x76fD77549A6659888d9dd71267ea65a4235f4928
            );
            deployParams.wstethAggregatorV3 = WStethRatiosAggregatorV3(
                0xA3B02E5620EeB6A42D119ea87961E053C2fD564E
            );
            deployParams
                .defaultProxyImplementation = DefaultProxyImplementation(
                0x3A328a73B48e70152215e6821A1a3d2733c94E40
            );
        } else {
            deployParams = commonContractsDeploy(deployParams);
        }

        n = 1;
        for (uint256 i = 0; i < n; i++) {
            deployParams.curator = curators[i];
            deployParams.lpTokenName = names[i];
            deployParams.lpTokenSymbol = symbols[i];
            (deployParams, setups[i]) = deploy(deployParams);
            validateParameters(deployParams, setups[i]);
            setups[i].depositWrapper.deposit{
                value: deployParams.firstDepositETH
            }(
                deployParams.deployer,
                address(0),
                deployParams.firstDepositETH,
                0,
                type(uint256).max
            );
        }

        vm.stopBroadcast();

        for (uint256 i = 0; i < n; i++) {
            logSetup(setups[i]);
        }
        logDeployParams(deployParams);

        // revert("Success");
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
        console2.log("TimeLockedCurator: ", address(setup.timeLockedCurator));
        console2.log("WstethAmountDeposited: ", setup.wstethAmountDeposited);
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
        console2.log("TimeLockDelay: ", deployParams.timeLockDelay);
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
