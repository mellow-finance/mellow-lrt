// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";
import "../unit/VaultTestCommon.t.sol";

contract DeployScript is Test {
    uint256 public constant Q96 = 2 ** 96;

    struct DeployParameters {
        address deployer;
        address vaultAdmin;
        address proposer;
        address acceptor;
        address emergencyOperator;
        address baseImplementation;
        string lpTokenName;
        string lpTokenSymbol;
        address defaultCollateralFactory;
    }

    struct DeploySetup {
        Vault vault;
        IVaultConfigurator configurator;
        ERC20TvlModule erc20TvlModule;
        DefaultBondTvlModule defaultBondTvlModule;
        DefaultBondModule defaultBondModule;
        ManagedValidator validator;
        ManagedRatiosOracle ratiosOracle;
        ChainlinkOracle priceOracle;
        DefaultBondStrategy defaultBondStrategy;
        DepositWrapper depositWrapper;
        address wstethDefaultBond;
        address defaultProxyImplementation;
        AdminProxy adminProxy;
    }

    function deploy(
        DeployParameters memory deployParams
    ) external returns (DeploySetup memory s) {
        vm.startPrank(deployParams.deployer);
        {
            Vault singleton = new Vault(
                deployParams.lpTokenName,
                deployParams.lpTokenSymbol,
                deployParams.vaultAdmin
            );

            s.defaultProxyImplementation = address(
                new DefaultProxyImplementation(
                    deployParams.lpTokenName,
                    deployParams.lpTokenSymbol
                )
            );

            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
                address(singleton),
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
                    implementation: s.defaultProxyImplementation,
                    callData: new bytes(0)
                })
            );

            ProxyAdmin(immutableProxyAdmin).transferOwnership(
                address(s.adminProxy)
            );
            s.vault = Vault(payable(proxy));
        }

        s.vault.grantRole(s.vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        s.vault.grantRole(s.vault.OPERATOR(), Constants.VAULT_ADMIN);

        s.configurator = s.vault.configurator();

        s.erc20TvlModule = new ERC20TvlModule();
        s.defaultBondTvlModule = new DefaultBondTvlModule();

        s.vault.addTvlModule(address(s.erc20TvlModule));
        s.vault.addTvlModule(address(s.defaultBondTvlModule));

        s.vault.addToken(Constants.WSTETH);
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
            s.priceOracle.setBaseToken(address(s.vault), Constants.WSTETH);
            s.configurator.stagePriceOracle(address(s.priceOracle));
            s.configurator.commitPriceOracle();
        }

        // setting initial total supply
        {
            s.configurator.stageMaximalTotalSupply(10_000 ether);
            s.configurator.commitMaximalTotalSupply();
        }

        // creating default bond factory and default bond contract for wsteth
        {
            // symbiotic contracts
            DefaultCollateralFactory defaultCollateralFactory = DefaultCollateralFactory(
                    deployParams.defaultCollateralFactory
                );
            s.wstethDefaultBond = defaultCollateralFactory.create(
                Constants.WSTETH,
                10_000 ether,
                Constants.VAULT_ADMIN
            );
            address[] memory supportedBonds = new address[](1);
            supportedBonds[0] = s.wstethDefaultBond;
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
            Constants.VAULT_ADMIN,
            s.vault,
            s.erc20TvlModule,
            s.defaultBondModule
        );

        {
            s.configurator.stageDepositCallback(address(s.defaultBondStrategy));
            s.configurator.commitDepositCallback();
        }

        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0].bond = s.wstethDefaultBond;
            data[0].ratioX96 = Q96;
            s.defaultBondStrategy.setData(Constants.WSTETH, data);
        }

        // validators setup
        s.validator = new ManagedValidator(Constants.VAULT_ADMIN);
        {
            s.validator.grantRole(
                address(s.defaultBondStrategy),
                Constants.DEFAULT_BOND_STRATEGY_ROLE
            );
            s.validator.grantContractRole(
                address(s.vault),
                Constants.DEFAULT_BOND_STRATEGY_ROLE
            );

            s.validator.grantRole(
                address(s.vault),
                Constants.DEFAULT_BOND_MODULE_ROLE
            );
            s.validator.grantContractRole(
                address(s.defaultBondModule),
                Constants.DEFAULT_BOND_MODULE_ROLE
            );

            s.validator.grantPublicRole(Constants.DEPOSITOR_ROLE);
            s.validator.grantContractSignatureRole(
                address(s.vault),
                IVault.deposit.selector,
                Constants.DEPOSITOR_ROLE
            );

            s.configurator.stageValidator(address(s.validator));
            s.configurator.commitValidator();
        }

        s.vault.grantRole(s.vault.OPERATOR(), address(s.defaultBondStrategy));

        s.depositWrapper = new DepositWrapper(
            s.vault,
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        vm.stopPrank();
    }
}
