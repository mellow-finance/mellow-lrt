// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployLibrary.sol";

contract DeployScript is Test {
    using SafeERC20 for IERC20;

    function test() external pure {}

    function deploy(
        DeployLibrary.DeployParameters memory deployParams
    ) internal returns (DeployLibrary.DeploySetup memory s) {
        vm.startPrank(deployParams.deployer);
        {
            s.initializer = new Initializer();

            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
                address(s.initializer),
                address(deployParams.deployer),
                new bytes(0)
            );

            Initializer(address(proxy)).initialize(
                deployParams.lpTokenName,
                deployParams.lpTokenSymbol,
                deployParams.deployer
            );

            address immutableProxyAdmin = address(
                uint160(
                    uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT))
                )
            );

            s.initialImplementation = new Vault("", "", address(1));
            ProxyAdmin(immutableProxyAdmin).upgradeAndCall(
                ITransparentUpgradeableProxy(address(proxy)),
                address(s.initialImplementation),
                new bytes(0)
            );

            s.defaultProxyImplementation = new DefaultProxyImplementation(
                deployParams.lpTokenName,
                deployParams.lpTokenSymbol
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
        s.vault.grantRole(s.vault.ADMIN_ROLE(), deployParams.admin);
        s.vault.grantRole(s.vault.ADMIN_DELEGATE_ROLE(), deployParams.curator);

        s.configurator = s.vault.configurator();

        s.erc20TvlModule = new ERC20TvlModule();
        s.defaultBondTvlModule = new DefaultBondTvlModule();

        s.vault.addTvlModule(address(s.erc20TvlModule));
        s.vault.addTvlModule(address(s.defaultBondTvlModule));

        s.vault.addToken(deployParams.wsteth);
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
            s.wstethAggregatorV3 = new WStethRatiosAggregatorV3(
                deployParams.wsteth
            );

            address[] memory tokens = new address[](2);
            tokens[0] = deployParams.weth;
            tokens[1] = deployParams.wsteth;
            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](2);
            data[0].aggregatorV3 = address(s.wethAggregatorV3);
            data[0].maxAge = 0;
            data[1].aggregatorV3 = address(s.wstethAggregatorV3);
            data[1].maxAge = 0;

            s.priceOracle.setBaseToken(address(s.vault), deployParams.weth);
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
            s.defaultBondStrategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.OPERATOR(),
            deployParams.operator
        );
        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.ADMIN_ROLE(),
            deployParams.curator
        );

        {
            s.configurator.stageDepositCallback(address(s.defaultBondStrategy));
            s.configurator.commitDepositCallback();
        }

        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0].bond = deployParams.wstethDefaultBond;
            data[0].ratioX96 = DeployConstants.Q96;
            s.defaultBondStrategy.setData(deployParams.wsteth, data);
        }

        // validators setup
        s.validator = new ManagedValidator(deployParams.deployer);
        s.validator.grantRole(
            deployParams.admin,
            DeployConstants.ADMIN_ROLE_BIT // ADMIN_ROLE_MASK = (1 << 255)
        );
        s.validator.grantRole(
            deployParams.curator,
            DeployConstants.ADMIN_ROLE_BIT // ADMIN_ROLE_MASK = (1 << 255)
        );
        {
            s.validator.grantRole(
                address(s.defaultBondStrategy),
                DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );
            s.validator.grantContractRole(
                address(s.vault),
                DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );

            s.validator.grantRole(
                address(s.vault),
                DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT
            );
            s.validator.grantContractRole(
                address(s.defaultBondModule),
                DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT
            );

            s.validator.grantPublicRole(DeployConstants.DEPOSITOR_ROLE_BIT);
            s.validator.grantContractSignatureRole(
                address(s.vault),
                IVault.deposit.selector,
                DeployConstants.DEPOSITOR_ROLE_BIT
            );

            s.configurator.stageValidator(address(s.validator));
            s.configurator.commitValidator();
        }

        s.vault.grantRole(s.vault.OPERATOR(), address(s.defaultBondStrategy));

        s.depositWrapper = new DepositWrapper(
            s.vault,
            deployParams.weth,
            deployParams.steth,
            deployParams.wsteth
        );

        // setting all configurator
        {
            s.configurator.stageDepositCallbackDelay(1 days);
            s.configurator.commitDepositCallbackDelay();

            s.configurator.stageWithdrawalCallbackDelay(1 days);
            s.configurator.commitWithdrawalCallbackDelay();

            s.configurator.stageWithdrawalFeeD9Delay(30 days);
            s.configurator.commitWithdrawalFeeD9Delay();

            s.configurator.stageMaximalTotalSupplyDelay(1 days);
            s.configurator.commitMaximalTotalSupplyDelay();

            s.configurator.stageDepositsLockedDelay(1 hours);
            s.configurator.commitDepositsLockedDelay();

            s.configurator.stageTransfersLockedDelay(365 days);
            s.configurator.commitTransfersLockedDelay();

            s.configurator.stageDelegateModuleApprovalDelay(1 days);
            s.configurator.commitDelegateModuleApprovalDelay();

            s.configurator.stageRatiosOracleDelay(30 days);
            s.configurator.commitRatiosOracleDelay();

            s.configurator.stagePriceOracleDelay(30 days);
            s.configurator.commitPriceOracleDelay();

            s.configurator.stageValidatorDelay(30 days);
            s.configurator.commitValidatorDelay();

            s.configurator.stageEmergencyWithdrawalDelay(90 days);
            s.configurator.commitEmergencyWithdrawalDelay();

            s.configurator.stageBaseDelay(30 days);
            s.configurator.commitBaseDelay();
        }

        // initial deposit
        {
            assertTrue(
                deployParams.initialDepositETH > 0,
                "Invalid deploy params. Initial deposit value is 0"
            );
            assertTrue(
                deployParams.deployer.balance >= deployParams.initialDepositETH,
                "Insufficient ETH amount for deposit"
            );
            // eth -> steth -> wsteth
            ISteth(deployParams.steth).submit{
                value: deployParams.initialDepositETH
            }(address(0));
            IERC20(deployParams.steth).safeIncreaseAllowance(
                deployParams.wsteth,
                deployParams.initialDepositETH
            );
            uint256 wstethAmountBefore = IERC20(deployParams.wsteth).balanceOf(
                deployParams.deployer
            );
            IWSteth(deployParams.wsteth).wrap(deployParams.initialDepositETH);
            uint256 wstethAmount = IERC20(deployParams.wsteth).balanceOf(
                deployParams.deployer
            ) - wstethAmountBefore;
            IERC20(deployParams.wsteth).safeIncreaseAllowance(
                address(s.vault),
                wstethAmount
            );
            assertTrue(wstethAmount > 0);
            address[] memory tokens = new address[](1);
            tokens[0] = deployParams.wsteth;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = wstethAmount;
            s.vault.deposit(
                address(s.vault),
                amounts,
                deployParams.initialDepositETH,
                type(uint256).max,
                0
            );
            s.wstethAmountDeposited = wstethAmount;
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
            s.defaultBondStrategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.renounceRole(
            s.defaultBondStrategy.OPERATOR(),
            deployParams.deployer
        );
        s.validator.revokeRole(
            deployParams.deployer,
            DeployConstants.ADMIN_ROLE_BIT
        );

        vm.stopPrank();
    }

    function validateChainId() internal view {
        if (block.chainid == 17000) return;
        revert(
            string(
                abi.encodePacked(
                    "Wrong chain id. Expected chain id: 17000, actual: ",
                    Strings.toString(block.chainid)
                )
            )
        );
    }
}
