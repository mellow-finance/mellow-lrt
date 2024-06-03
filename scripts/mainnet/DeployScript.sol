// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployLibrary.sol";

contract DeployScript is CommonBase {
    using SafeERC20 for IERC20;

    function commonContractsDeploy(
        DeployLibrary.DeployParameters memory deployParams
    ) public returns (DeployLibrary.DeployParameters memory) {
        if (address(deployParams.initializer) == address(0))
            deployParams.initializer = new Initializer();
        if (address(deployParams.erc20TvlModule) == address(0))
            deployParams.erc20TvlModule = new ERC20TvlModule();
        if (address(deployParams.defaultBondModule) == address(0))
            deployParams.defaultBondModule = new DefaultBondModule();
        if (address(deployParams.defaultBondTvlModule) == address(0))
            deployParams.defaultBondTvlModule = new DefaultBondTvlModule();
        if (address(deployParams.ratiosOracle) == address(0))
            deployParams.ratiosOracle = new ManagedRatiosOracle();
        if (address(deployParams.priceOracle) == address(0))
            deployParams.priceOracle = new ChainlinkOracle();
        if (address(deployParams.wethAggregatorV3) == address(0))
            deployParams.wethAggregatorV3 = new ConstantAggregatorV3(1 ether);
        if (address(deployParams.wstethAggregatorV3) == address(0))
            deployParams.wstethAggregatorV3 = new WStethRatiosAggregatorV3(
                deployParams.wsteth
            );
        if (address(deployParams.defaultProxyImplementation) == address(0))
            deployParams
                .defaultProxyImplementation = new DefaultProxyImplementation(
                "",
                ""
            );
        return deployParams;
    }

    function deploy(
        DeployLibrary.DeployParameters memory deployParams
    )
        internal
        returns (
            DeployLibrary.DeployParameters memory,
            DeployLibrary.DeploySetup memory s
        )
    {
        deployParams = commonContractsDeploy(deployParams);

        {
            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
                address(deployParams.initializer),
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

            ProxyAdmin(immutableProxyAdmin).transferOwnership(
                address(deployParams.proxyAdmin)
            );
            s.vault = Vault(payable(proxy));
        }

        // setup timelocked controller
        {
            address[] memory proposers = new address[](1);
            proposers[0] = deployParams.curator;
            address[] memory executors = new address[](1);
            executors[0] = deployParams.curator;
            s.timeLockedCurator = new TimelockController(
                deployParams.timeLockDelay,
                proposers,
                executors,
                deployParams.admin
            );
        }

        s.vault.grantRole(s.vault.ADMIN_DELEGATE_ROLE(), deployParams.deployer);
        s.vault.grantRole(s.vault.ADMIN_ROLE(), deployParams.admin);
        s.vault.grantRole(
            s.vault.ADMIN_DELEGATE_ROLE(),
            address(s.timeLockedCurator)
        );

        s.configurator = s.vault.configurator();

        s.vault.addTvlModule(address(deployParams.erc20TvlModule));
        s.vault.addTvlModule(address(deployParams.defaultBondTvlModule));

        s.vault.addToken(deployParams.wsteth);
        // oracles setup
        {
            uint128[] memory ratiosX96 = new uint128[](1);
            ratiosX96[0] = 2 ** 96; // WSTETH deposit
            deployParams.ratiosOracle.updateRatios(
                address(s.vault),
                true,
                ratiosX96
            );
            ratiosX96[0] = 2 ** 96; // WSTETH withdrawal
            deployParams.ratiosOracle.updateRatios(
                address(s.vault),
                false,
                ratiosX96
            );

            s.configurator.stageRatiosOracle(
                address(deployParams.ratiosOracle)
            );
            s.configurator.commitRatiosOracle();

            address[] memory tokens = new address[](2);
            tokens[0] = deployParams.weth;
            tokens[1] = deployParams.wsteth;
            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](2);
            data[0].aggregatorV3 = address(deployParams.wethAggregatorV3);
            data[0].maxAge = 0;
            data[1].aggregatorV3 = address(deployParams.wstethAggregatorV3);
            data[1].maxAge = 0;

            deployParams.priceOracle.setBaseToken(
                address(s.vault),
                deployParams.weth
            );
            deployParams.priceOracle.setChainlinkOracles(
                address(s.vault),
                tokens,
                data
            );

            s.configurator.stagePriceOracle(address(deployParams.priceOracle));
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
            deployParams.defaultBondTvlModule.setParams(
                address(s.vault),
                supportedBonds
            );
        }

        s.configurator.stageDelegateModuleApproval(
            address(deployParams.defaultBondModule)
        );
        s.configurator.commitDelegateModuleApproval(
            address(deployParams.defaultBondModule)
        );

        s.defaultBondStrategy = new DefaultBondStrategy(
            deployParams.deployer,
            s.vault,
            deployParams.erc20TvlModule,
            deployParams.defaultBondModule
        );

        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.ADMIN_ROLE(),
            deployParams.admin
        );
        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.OPERATOR(),
            address(deployParams.curator)
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
                address(deployParams.defaultBondModule),
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
            require(
                deployParams.initialDepositETH > 0,
                "Invalid deploy params. Initial deposit value is 0"
            );
            require(
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
            IWSteth(deployParams.wsteth).wrap(deployParams.initialDepositETH);
            uint256 wstethAmount = IERC20(deployParams.wsteth).balanceOf(
                deployParams.deployer
            );
            IERC20(deployParams.wsteth).safeIncreaseAllowance(
                address(s.vault),
                wstethAmount
            );
            require(wstethAmount > 0, "No wsteth received");
            address[] memory tokens = new address[](1);
            tokens[0] = deployParams.wsteth;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = wstethAmount;
            s.vault.deposit(
                address(s.vault),
                amounts,
                deployParams.initialDepositETH,
                type(uint256).max
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

        return (deployParams, s);
    }

    function validateChainId() internal view {
        uint256 chainId = block.chainid;
        if (chainId != 1) {
            revert(
                string(
                    abi.encodePacked(
                        "Wrong chain id. Expected chain id: 1, actual: %d",
                        Strings.toString(chainId)
                    )
                )
            );
        }
    }
}
