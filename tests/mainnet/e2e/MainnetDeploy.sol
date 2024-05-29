// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./IDeploy.sol";

contract DeployScript is Test {
    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE = 2;
    uint8 public constant ADMIN_ROLE = 255;

    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function deploy(
        IDeploy.DeployParameters memory deployParams
    ) external returns (IDeploy.DeploySetup memory s) {
        vm.startPrank(deployParams.deployer);
        {
            s.initialImplementation = new Vault(
                deployParams.lpTokenName,
                deployParams.lpTokenSymbol,
                deployParams.deployer
            );

            s.defaultProxyImplementation = new DefaultProxyImplementation(
                deployParams.lpTokenName,
                deployParams.lpTokenSymbol
            );

            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
                address(s.initialImplementation),
                address(deployParams.deployer),
                new bytes(0)
            );

            address immutableProxyAdmin = address(
                uint160(
                    uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT))
                )
            );

            s.adminProxy = new AdminProxy(
                address(proxy),
                immutableProxyAdmin,
                deployParams.acceptor,
                deployParams.proposer,
                deployParams.emergencyOperator,
                IAdminProxy.Proposal({
                    implementation: address(s.defaultProxyImplementation),
                    callData: new bytes(0)
                })
            );

            ProxyAdmin(immutableProxyAdmin).transferOwnership(
                address(s.adminProxy)
            );
            s.vault = Vault(payable(proxy));
        }

        s.vault.grantRole(s.vault.ADMIN_DELEGATE_ROLE(), deployParams.deployer);
        s.vault.grantRole(
            s.vault.ADMIN_DELEGATE_ROLE(),
            address(s.restrictingKeeper)
        );
        s.vault.grantRole(s.vault.ADMIN_ROLE(), deployParams.vaultAdmin);
        s.vault.grantRole(
            s.vault.ADMIN_DELEGATE_ROLE(),
            deployParams.vaultCurator
        );

        s.configurator = s.vault.configurator();

        s.erc20TvlModule = new ERC20TvlModule();
        s.defaultBondTvlModule = new DefaultBondTvlModule();

        s.vault.addTvlModule(address(s.erc20TvlModule));
        s.vault.addTvlModule(address(s.defaultBondTvlModule));

        s.vault.addToken(WSTETH);
        // oracles setup
        {
            s.ratiosOracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](1);
            ratiosX96[0] = 2 ** 96; // WSTETH deposit
            s.ratiosOracle.updateRatios(address(s.vault), true, ratiosX96);
            ratiosX96[0] = 2 ** 96; // WSTETH withdrawal
            s.ratiosOracle.updateRatios(address(s.vault), false, ratiosX96);

            s.configurator.stageRatiosOracle(address(s.ratiosOracle));
            s.configurator.commitRatiosOracle();

            s.priceOracle = new ChainlinkOracle();

            s.wethAggregatorV3 = new ConstantAggregatorV3(1 ether);
            s.wstethAggregatorV3 = new WStethRatiosAggregatorV3(WSTETH);

            address[] memory tokens = new address[](2);
            tokens[0] = WETH;
            tokens[1] = WSTETH;
            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](2);
            data[0].aggregatorV3 = address(s.wethAggregatorV3);
            data[0].maxAge = 0;
            data[1].aggregatorV3 = address(s.wstethAggregatorV3);
            data[1].maxAge = 0;

            s.priceOracle.setBaseToken(address(s.vault), WETH);
            s.priceOracle.setChainlinkOracles(address(s.vault), tokens, data);

            s.configurator.stagePriceOracle(address(s.priceOracle));
            s.configurator.commitPriceOracle();
        }

        // setting initial total supply
        {
            s.configurator.stageMaximalTotalSupply(
                deployParams.maximalTotalSupply
            );
            s.configurator.commitMaximalTotalSupply();
        }

        // setting params for wsteth default bond in defaultBondTvlModule
        {
            address[] memory supportedBonds = new address[](1);
            supportedBonds[0] = deployParams.wstethDefaultBond;
            s.defaultBondTvlModule.setParams(address(s.vault), supportedBonds);
        }

        s.defaultBondModule = new DefaultBondModule();

        s.configurator.stageDelegateModuleApproval(
            address(s.defaultBondModule)
        );
        s.configurator.commitDelegateModuleApproval(
            address(s.defaultBondModule)
        );

        s.defaultBondStrategy = new DefaultBondStrategy(
            deployParams.deployer,
            s.vault,
            s.erc20TvlModule,
            s.defaultBondModule
        );

        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.ADMIN_ROLE(),
            deployParams.vaultAdmin
        );

        {
            s.configurator.stageDepositCallback(address(s.defaultBondStrategy));
            s.configurator.commitDepositCallback();
        }

        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0].bond = deployParams.wstethDefaultBond;
            data[0].ratioX96 = Q96;
            s.defaultBondStrategy.setData(WSTETH, data);
        }

        // validators setup
        s.validator = new ManagedValidator(deployParams.deployer);
        s.validator.grantRole(
            deployParams.vaultAdmin,
            ADMIN_ROLE // ADMIN_ROLE_MASK = (1 << 255)
        );
        {
            s.validator.grantRole(
                address(s.defaultBondStrategy),
                DEFAULT_BOND_STRATEGY_ROLE
            );
            s.validator.grantContractRole(
                address(s.vault),
                DEFAULT_BOND_STRATEGY_ROLE
            );

            s.validator.grantRole(address(s.vault), DEFAULT_BOND_MODULE_ROLE);
            s.validator.grantContractRole(
                address(s.defaultBondModule),
                DEFAULT_BOND_MODULE_ROLE
            );

            s.validator.grantPublicRole(DEPOSITOR_ROLE);
            s.validator.grantContractSignatureRole(
                address(s.vault),
                IVault.deposit.selector,
                DEPOSITOR_ROLE
            );

            s.configurator.stageValidator(address(s.validator));
            s.configurator.commitValidator();
        }

        s.vault.grantRole(s.vault.OPERATOR(), address(s.defaultBondStrategy));

        s.depositWrapper = new DepositWrapper(s.vault, WETH, STETH, WSTETH);

        // setting all configurator
        {

        }

        s.vault.renounceRole(s.vault.ADMIN_ROLE(), deployParams.deployer);
        s.vault.renounceRole(
            s.vault.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.vault.renounceRole(s.vault.OPERATOR(), deployParams.deployer);

        s.defaultBondStrategy.renounceRole(
            s.defaultBondStrategy.ADMIN_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.renounceRole(
            s.defaultBondStrategy.OPERATOR(),
            deployParams.deployer
        );
        s.validator.revokeRole(deployParams.deployer, ADMIN_ROLE);

        vm.stopPrank();
    }
}
