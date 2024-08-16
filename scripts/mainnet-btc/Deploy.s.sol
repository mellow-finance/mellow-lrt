// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";
import "./Validator.sol";
import "./EventValidator.sol";

contract Deploy is Script, DeployScript, Validator, EventValidator {
    function run() external {
        uint256 n = 1;

        address[] memory curators = new address[](n);
        curators[0] = DeployConstants.MEV_WBTC_CURATOR;

        string[] memory names = new string[](n);
        names[0] = DeployConstants.MEV_WBTC_VAULT_NAME;

        string[] memory symbols = new string[](n);
        symbols[0] = DeployConstants.MEV_WBTC_VAULT_SYMBOL;

        address[] memory underlyingTokens = new address[](n);
        underlyingTokens[0] = DeployConstants.WBTC;

        address[] memory bonds = new address[](n);
        bonds[0] = DeployConstants.WBTC_DEFAULT_BOND;

        uint256[] memory maximalTotalSupplies = new uint256[](n);
        maximalTotalSupplies[0] = DeployConstants.WBTC_VAULT_LIMIT;

        DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                proxyAdmin: DeployConstants.MELLOW_WBTC_PROXY_MULTISIG,
                admin: DeployConstants.MELLOW_WBTC_MULTISIG,
                curators: curators,
                lpTokenName: "",
                lpTokenSymbol: "",
                defaultBond: address(0),
                defaultBondFactory: DeployConstants.DEFAULT_BOND_FACTORY,
                underlyingToken: address(0),
                maximalTotalSupply: 0,
                initialDeposit: DeployConstants.INITIAL_DEPOSIT,
                initializer: Initializer(
                    0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c
                ),
                initialImplementation: Vault(
                    payable(0xaf108ae0AD8700ac41346aCb620e828c03BB8848)
                ),
                erc20TvlModule: ERC20TvlModule(
                    0x1EB0e946D7d757d7b085b779a146427e40ABBCf8
                ),
                defaultBondTvlModule: DefaultBondTvlModule(
                    0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429
                ),
                defaultBondModule: DefaultBondModule(
                    0xD8619769fed318714d362BfF01CA98ac938Bdf9b
                ),
                ratiosOracle: ManagedRatiosOracle(
                    0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d
                ),
                priceOracle: ChainlinkOracle(
                    0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d
                ),
                constantAggregatorV3: IAggregatorV3(
                    0x6A8d8033de46c68956CCeBA28Ba1766437FF840F
                ),
                defaultProxyImplementation: DefaultProxyImplementation(
                    0x02BB349832c58E892a20178b9696e2b93A3a9b0f
                )
            });

        DeployInterfaces.DeploySetup[]
            memory setups = new DeployInterfaces.DeploySetup[](n);

        vm.startBroadcast(uint256(bytes32(vm.envBytes("MAINNET_DEPLOYER"))));
        //vm.startPrank(DeployConstants.MAINNET_DEPLOYER);

        deployParams = commonContractsDeploy(deployParams);
        for (uint256 i = 0; i < n; i++) {
            deployParams.lpTokenName = names[i];
            deployParams.lpTokenSymbol = symbols[i];
            deployParams.defaultBond = bonds[i];
            deployParams.underlyingToken = underlyingTokens[i];
            deployParams.maximalTotalSupply = maximalTotalSupplies[i];

            (deployParams, setups[i]) = deploy(deployParams);
            validateParameters(deployParams, setups[i], 0);
            validateEvents(deployParams, setups[i], vm.getRecordedLogs());
        }

        vm.stopBroadcast();
        for (uint256 i = 0; i < n; i++) {
            logSetup(setups[i]);
        }
        logDeployParams(deployParams);

        //revert("success");
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
        console2.log("Curator: ", address(deployParams.curators[0]));
        console2.log(
            "DefaultBondFactory: ",
            address(deployParams.defaultBondFactory)
        );
        console2.log("DefaultBond: ", address(deployParams.defaultBond));
        console2.log(
            "UnderlyingToken: ",
            address(deployParams.underlyingToken)
        );
        console2.log("MaximalTotalSupply: ", deployParams.maximalTotalSupply);
        console2.log("LpTokenName: ", deployParams.lpTokenName);
        console2.log("LpTokenSymbol: ", deployParams.lpTokenSymbol);
        console2.log("InitialDepositETH: ", deployParams.initialDeposit);
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
            "ConstantAggregatorV3: ",
            address(deployParams.constantAggregatorV3)
        );
        console2.log(
            "DefaultProxyImplementation: ",
            address(deployParams.defaultProxyImplementation)
        );
        block.timestamp;
    }
}
