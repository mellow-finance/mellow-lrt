// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";
import "./Validator.sol";
import "./EventValidator.sol";

contract Deploy is Script, DeployScript, Validator, EventValidator {
    function run() external {
        DeployInterfaces.DeployParameters memory deployParams;

        bool test = true;
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

        deployParams.deployer = DeployConstants.MAINNET_TEST_DEPLOYER;
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("MAINNET_TEST_DEPLOYER")))
        );

        deployParams.proxyAdmin = DeployConstants
            .MELLOW_LIDO_TEST_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        // only for testing purposes
        if (test) {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND_TEST;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY_TEST;
            // TransparentUpgradeableProxy factory = new TransparentUpgradeableProxy(
            //         DeployConstants.WSTETH_DEFAULT_BOND_FACTORY,
            //         address(this),
            //         ""
            //     );
            // deployParams.wstethDefaultBond = IDefaultCollateralFactory(
            //     address(factory)
            // ).create(DeployConstants.WSTETH, type(uint256).max, address(0));
            // deployParams.wstethDefaultBondFactory = address(factory);
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

        DeployInterfaces.DeploySetup[]
            memory setups = new DeployInterfaces.DeploySetup[](n);

        deployParams.initializer = Initializer(
            0x8f06BEB555D57F0D20dB817FF138671451084e24
        );
        deployParams.initialImplementation = Vault(
            payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)
        );
        deployParams.erc20TvlModule = ERC20TvlModule(
            0xCA60f449867c9101Ec80F8C611eaB39afE7bD638
        );
        deployParams.defaultBondModule = DefaultBondModule(
            0x204043f4bda61F719Ad232b4196E1bc4131a3096
        );
        deployParams.defaultBondTvlModule = DefaultBondTvlModule(
            0x48f758bd51555765EBeD4FD01c85554bD0B3c03B
        );
        deployParams.ratiosOracle = ManagedRatiosOracle(
            0x1437DCcA4e1442f20285Fb7C11805E7a965681e2
        );
        deployParams.priceOracle = ChainlinkOracle(
            0xA5046e9379B168AFA154504Cf16853B6a7728436
        );
        deployParams.wethAggregatorV3 = ConstantAggregatorV3(
            0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09
        );
        deployParams.wstethAggregatorV3 = WStethRatiosAggregatorV3(
            0x773ae8ca45D5701131CA84C58821a39DdAdC709c
        );
        deployParams.defaultProxyImplementation = DefaultProxyImplementation(
            0x538459eeA06A06018C70bf9794e1c7b298694828
        );

        deployParams = commonContractsDeploy(deployParams);
        n = 1;
        for (uint256 i = 0; i < n; i++) {
            deployParams.curator = curators[i];
            deployParams.lpTokenName = names[i];
            deployParams.lpTokenSymbol = symbols[i];

            vm.recordLogs();
            (deployParams, setups[i]) = deploy(deployParams);
            validateParameters(deployParams, setups[i]);
            validateEvents(deployParams, setups[i], vm.getRecordedLogs());
            if (false) {
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
        }

        vm.stopBroadcast();

        for (uint256 i = 0; i < n; i++) {
            logSetup(setups[i]);
        }
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
