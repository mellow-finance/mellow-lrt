// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

abstract contract DeployScript is CommonBase {
    using SafeERC20 for IERC20;

    function commonContractsDeploy(
        DeployInterfaces.DeployParameters memory deployParams
    ) public returns (DeployInterfaces.DeployParameters memory) {
        if (address(deployParams.initializer) == address(0))
            deployParams.initializer = new Initializer();
        if (address(deployParams.initialImplementation) == address(0))
            deployParams.initialImplementation = new Vault(
                "",
                "",
                address(0xdead)
            );
        if (address(deployParams.erc20TvlModule) == address(0))
            deployParams.erc20TvlModule = new ERC20TvlModule();
        if (address(deployParams.stakingModule) == address(0))
            deployParams.stakingModule = new StakingModule(
                DeployConstants.WETH,
                DeployConstants.STETH,
                DeployConstants.WSTETH,
                ILidoLocator(DeployConstants.LIDO_LOCATOR),
                IWithdrawalQueue(DeployConstants.WITHDRAWAL_QUEUE),
                DeployConstants.SIMPLE_DVT_MODULE_ID
            );
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
        DeployInterfaces.DeployParameters memory deployParams
    )
        internal
        returns (
            DeployInterfaces.DeployParameters memory,
            DeployInterfaces.DeploySetup memory s
        )
    {
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

            s.proxyAdmin = ProxyAdmin(
                address(
                    uint160(
                        uint256(
                            vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)
                        )
                    )
                )
            );
            s.proxyAdmin.upgradeAndCall(
                ITransparentUpgradeableProxy(address(proxy)),
                address(deployParams.initialImplementation),
                new bytes(0)
            );

            s.proxyAdmin.transferOwnership(address(deployParams.proxyAdmin));
            s.vault = Vault(payable(proxy));
        }

        s.vault.grantRole(s.vault.ADMIN_DELEGATE_ROLE(), deployParams.deployer);
        s.vault.grantRole(s.vault.ADMIN_ROLE(), deployParams.admin);

        s.configurator = s.vault.configurator();

        s.vault.addTvlModule(address(deployParams.erc20TvlModule));

        s.vault.addToken(deployParams.weth);
        s.vault.addToken(deployParams.wsteth);
        // oracles setup
        uint256 wethIndex = deployParams.weth < deployParams.wsteth ? 0 : 1;
        {
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[wethIndex] = 2 ** 96; // WETH deposit
            ratiosX96[wethIndex ^ 1] = 0;
            deployParams.ratiosOracle.updateRatios(
                address(s.vault),
                true,
                ratiosX96
            );
            ratiosX96[wethIndex ^ 1] = 2 ** 96; // WSTETH withdrawal
            ratiosX96[wethIndex] = 0;
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

        s.configurator.stageDelegateModuleApproval(
            address(deployParams.stakingModule)
        );
        s.configurator.commitDelegateModuleApproval(
            address(deployParams.stakingModule)
        );

        s.strategy = new SimpleDVTStakingStrategy(
            deployParams.deployer,
            s.vault,
            deployParams.stakingModule
        );

        s.strategy.grantRole(s.strategy.ADMIN_ROLE(), deployParams.admin);
        s.strategy.grantRole(
            s.strategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.strategy.grantRole(
            s.strategy.OPERATOR(),
            address(deployParams.curatorOperator)
        );

        // validators setup
        s.validator = new ManagedValidator(deployParams.deployer);
        s.validator.grantRole(
            deployParams.admin,
            DeployConstants.ADMIN_ROLE_BIT // ADMIN_ROLE_MASK = (1 << 255)
        );
        {
            s.validator.grantRole(
                address(s.strategy),
                DeployConstants.DELEGATE_CALLER_ROLE_BIT
            );
            s.validator.grantRole(
                address(deployParams.curatorAdmin),
                DeployConstants.DELEGATE_CALLER_ROLE_BIT
            );
            s.validator.grantContractSignatureRole(
                address(s.vault),
                IVault.delegateCall.selector,
                DeployConstants.DELEGATE_CALLER_ROLE_BIT
            );

            s.validator.grantRole(address(s.vault), DeployConstants.VAULT_ROLE);

            s.validator.grantContractRole(
                address(deployParams.stakingModule),
                DeployConstants.VAULT_ROLE
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

        s.vault.grantRole(s.vault.OPERATOR(), address(s.strategy));

        // setting all configurator
        {
            s.configurator.stageDepositCallbackDelay(1 days);
            s.configurator.commitDepositCallbackDelay();

            s.configurator.stageWithdrawalCallbackDelay(1 days);
            s.configurator.commitWithdrawalCallbackDelay();

            s.configurator.stageWithdrawalFeeD9Delay(30 days);
            s.configurator.commitWithdrawalFeeD9Delay();

            s.configurator.stageMaximalTotalSupplyDelay(1 hours);
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
                IERC20(deployParams.weth).balanceOf(deployParams.deployer) >=
                    deployParams.initialDepositETH,
                "Insufficient WETH amount for deposit"
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[wethIndex] = deployParams.initialDepositETH;
            IERC20(deployParams.weth).safeIncreaseAllowance(
                address(s.vault),
                deployParams.initialDepositETH
            );

            s.vault.deposit(
                address(s.vault),
                amounts,
                deployParams.initialDepositETH,
                type(uint256).max,
                0
            );
        }

        s.vault.renounceRole(s.vault.ADMIN_ROLE(), deployParams.deployer);
        s.vault.renounceRole(
            s.vault.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.vault.renounceRole(s.vault.OPERATOR(), deployParams.deployer);

        s.strategy.renounceRole(s.strategy.ADMIN_ROLE(), deployParams.deployer);
        s.strategy.renounceRole(
            s.strategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.strategy.renounceRole(s.strategy.OPERATOR(), deployParams.deployer);
        s.validator.revokeRole(
            deployParams.deployer,
            DeployConstants.ADMIN_ROLE_BIT
        );

        return (deployParams, s);
    }

    function testDeployScript() external pure {}
}
