// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

contract Validator {
    function test() external pure {}

    function validateParameters(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup
    ) public view {
        // vault permissions

        bytes32 ADMIN_ROLE = keccak256("admin");
        bytes32 ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
        bytes32 OPERATOR_ROLE = keccak256("operator");

        uint256 ADMIN_ROLE_MASK = 1 << 255;
        uint256 DEPOSITOR_ROLE_MASK = 1 << 0;
        uint256 DEFAULT_BOND_STRATEGY_ROLE_MASK = 1 << 1;
        uint256 DEFAULT_BOND_MODULE_ROLE_MASK = 1 << 2;

        // TimelockController
        {
            TimelockController timelock = setup.timeLockedCurator;
            require(
                timelock.hasRole(
                    timelock.DEFAULT_ADMIN_ROLE(),
                    deployParams.admin
                )
            );
            require(
                timelock.hasRole(timelock.PROPOSER_ROLE(), deployParams.curator)
            );
            require(
                timelock.hasRole(
                    timelock.CANCELLER_ROLE(),
                    deployParams.curator
                )
            );
            require(
                timelock.hasRole(timelock.EXECUTOR_ROLE(), deployParams.curator)
            );
        }

        // Vault permissions
        {
            Vault vault = setup.vault;
            require(
                vault.getRoleMemberCount(ADMIN_ROLE) == 1,
                "Wrong admin count"
            );
            require(
                vault.hasRole(ADMIN_ROLE, deployParams.admin),
                "Admin not set"
            );
            require(
                vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 1,
                "Wrong admin delegate count"
            );
            require(
                !vault.hasRole(
                    ADMIN_DELEGATE_ROLE,
                    address(deployParams.curator)
                ),
                "Wrong curator"
            );
            require(
                vault.hasRole(
                    ADMIN_DELEGATE_ROLE,
                    address(setup.timeLockedCurator)
                ),
                "Curator not set"
            );
            require(vault.getRoleMemberCount(OPERATOR_ROLE) == 1);
            require(
                vault.hasRole(OPERATOR_ROLE, address(setup.defaultBondStrategy))
            );
        }

        // DefaultBondStrategy permissions
        {
            DefaultBondStrategy strategy = setup.defaultBondStrategy;
            require(
                strategy.getRoleMemberCount(ADMIN_ROLE) == 1,
                "Admin not set"
            );
            require(strategy.hasRole(ADMIN_ROLE, deployParams.admin));
            require(strategy.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 0);
            require(strategy.getRoleMemberCount(OPERATOR_ROLE) == 1);
            require(strategy.hasRole(OPERATOR_ROLE, deployParams.curator));
        }

        // Managed validator permissions
        {
            ManagedValidator validator = setup.validator;
            require(validator.publicRoles() == DEPOSITOR_ROLE_MASK);

            require(
                validator.userRoles(deployParams.deployer) == 0,
                "Deployer has roles"
            );
            require(
                validator.userRoles(deployParams.admin) == ADMIN_ROLE_MASK,
                "Admin has no roles"
            );
            require(
                validator.userRoles(address(setup.timeLockedCurator)) == 0,
                "Time locked curator has roles"
            );
            if (deployParams.curator != deployParams.admin) {
                require(
                    validator.userRoles(deployParams.curator) == 0,
                    "Curator has roles"
                );
            }

            require(
                validator.userRoles(address(setup.defaultBondStrategy)) ==
                    DEFAULT_BOND_STRATEGY_ROLE_MASK
            );
            require(
                validator.userRoles(address(setup.vault)) ==
                    DEFAULT_BOND_MODULE_ROLE_MASK
            );

            require(
                validator.allowAllSignaturesRoles(
                    address(setup.defaultBondStrategy)
                ) == 0
            );
            require(
                validator.allowAllSignaturesRoles(address(setup.vault)) ==
                    DEFAULT_BOND_STRATEGY_ROLE_MASK
            );
            require(
                validator.allowAllSignaturesRoles(
                    address(deployParams.defaultBondModule)
                ) == DEFAULT_BOND_MODULE_ROLE_MASK
            );
            require(
                validator.allowSignatureRoles(
                    address(setup.vault),
                    IVault.deposit.selector
                ) == DEPOSITOR_ROLE_MASK
            );
        }

        // Vault balances
        {
            require(setup.vault.balanceOf(deployParams.deployer) == 0);
            require(
                setup.vault.balanceOf(address(setup.vault)) ==
                    deployParams.initialDepositETH,
                "Invalid vault balance"
            );
            require(
                setup.vault.totalSupply() == deployParams.initialDepositETH,
                "Invalid total supply"
            );
            require(
                IERC20(deployParams.wsteth).balanceOf(address(setup.vault)) ==
                    0,
                "Invalid wsteth balance of vault"
            );
            uint256 bondBalance = IERC20(deployParams.wstethDefaultBond)
                .balanceOf(address(setup.vault));
            require(
                bondBalance == setup.wstethAmountDeposited,
                "Invalid bond balance"
            );
            require(
                IERC20(deployParams.wsteth).balanceOf(
                    deployParams.wstethDefaultBond
                ) >= bondBalance,
                "Invalid wsteth balance of bond"
            );
            uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
                .getStETHByWstETH(bondBalance);
            // at most 2 weis loss due to eth->steth && steth->wsteth conversions
            require(
                deployParams.initialDepositETH - 2 wei <= expectedStethAmount &&
                    expectedStethAmount <= deployParams.initialDepositETH,
                "Invalid steth amount"
            );
        }

        // Vault values
        {
            require(
                keccak256(bytes(setup.vault.name())) ==
                    keccak256(bytes(deployParams.lpTokenName))
            );
            require(
                keccak256(bytes(setup.vault.symbol())) ==
                    keccak256(bytes(deployParams.lpTokenSymbol))
            );
            require(setup.vault.decimals() == 18);

            require(
                address(setup.vault.configurator()) ==
                    address(setup.configurator)
            );
            address[] memory underlyingTokens = setup.vault.underlyingTokens();
            require(underlyingTokens.length == 1);
            require(underlyingTokens[0] == deployParams.wsteth);
            {
                address[] memory tvlModules = setup.vault.tvlModules();
                require(tvlModules.length == 2);
                require(tvlModules[0] == address(deployParams.erc20TvlModule));
                require(
                    tvlModules[1] == address(deployParams.defaultBondTvlModule)
                );
            }

            require(
                setup.vault.withdrawalRequest(deployParams.deployer).lpAmount ==
                    0
            );
            {
                address[] memory pendingWithdrawers = setup
                    .vault
                    .pendingWithdrawers();
                require(pendingWithdrawers.length == 0);
            }
            {
                (
                    address[] memory underlyingTvlTokens,
                    uint256[] memory underlyingTvlValues
                ) = setup.vault.underlyingTvl();
                require(underlyingTvlTokens.length == 1);
                require(underlyingTvlTokens[0] == deployParams.wsteth);

                require(underlyingTvlValues.length == 1);
                uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
                    .getStETHByWstETH(underlyingTvlValues[0]);
                // valid only for tests or right after deployment
                // after that getStETHByWstETH will return different ratios due to rebase logic
                require(
                    deployParams.initialDepositETH - 2 wei <=
                        expectedStethAmount &&
                        expectedStethAmount <= deployParams.initialDepositETH
                );
            }

            {
                (
                    address[] memory baseTvlTokens,
                    uint256[] memory baseTvlValues
                ) = setup.vault.baseTvl();
                require(baseTvlTokens.length == 2);
                require(baseTvlValues.length == 2);

                uint256 wstethIndex = deployParams.wsteth <
                    deployParams.wstethDefaultBond
                    ? 0
                    : 1;

                require(baseTvlTokens[wstethIndex] == deployParams.wsteth);
                require(
                    baseTvlTokens[wstethIndex ^ 1] ==
                        deployParams.wstethDefaultBond
                );

                require(baseTvlValues[wstethIndex] == 0);
                uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
                    .getStETHByWstETH(baseTvlValues[wstethIndex ^ 1]);
                // valid only for tests or right after deployment
                // after that getStETHByWstETH will return different ratios due to rebase logic
                require(
                    deployParams.initialDepositETH - 2 wei <=
                        expectedStethAmount &&
                        expectedStethAmount <= deployParams.initialDepositETH
                );
            }

            {
                require(
                    setup.vault.totalSupply() == deployParams.initialDepositETH
                );
                require(setup.vault.balanceOf(deployParams.deployer) == 0);
                require(
                    setup.vault.balanceOf(address(setup.vault)) ==
                        deployParams.initialDepositETH
                );

                IVault.ProcessWithdrawalsStack memory stack = setup
                    .vault
                    .calculateStack();

                address[] memory expectedTokens = new address[](1);
                expectedTokens[0] = deployParams.wsteth;
                require(
                    stack.tokensHash == keccak256(abi.encode(stack.tokens))
                );
                require(
                    stack.tokensHash == keccak256(abi.encode(expectedTokens))
                );

                require(stack.totalSupply == deployParams.initialDepositETH);
                require(
                    deployParams.initialDepositETH - 2 wei <=
                        stack.totalValue &&
                        stack.totalValue <= deployParams.initialDepositETH
                );

                require(stack.ratiosX96.length == 1);
                require(stack.ratiosX96[0] == DeployConstants.Q96);

                require(stack.erc20Balances.length == 1);
                require(stack.erc20Balances[0] == 0);

                uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
                    .getStETHByWstETH(DeployConstants.Q96);
                require(
                    stack.ratiosX96Value > 0 &&
                        stack.ratiosX96Value <= expectedStethAmount
                );
                assert(
                    (expectedStethAmount - stack.ratiosX96Value) <
                        stack.ratiosX96Value / 1e10
                );

                require(stack.timestamp == block.timestamp);
                require(stack.feeD9 == 0);
            }
        }

        // VaultConfigurator values
        {
            require(setup.configurator.baseDelay() == 30 days);
            require(setup.configurator.depositCallbackDelay() == 1 days);
            require(setup.configurator.withdrawalCallbackDelay() == 1 days);
            require(setup.configurator.withdrawalFeeD9Delay() == 30 days);
            require(setup.configurator.maximalTotalSupplyDelay() == 1 days);
            require(setup.configurator.isDepositLockedDelay() == 1 hours);
            require(setup.configurator.areTransfersLockedDelay() == 365 days);
            require(setup.configurator.delegateModuleApprovalDelay() == 1 days);
            require(setup.configurator.ratiosOracleDelay() == 30 days);
            require(setup.configurator.priceOracleDelay() == 30 days);
            require(setup.configurator.validatorDelay() == 30 days);
            require(setup.configurator.emergencyWithdrawalDelay() == 90 days);
            require(
                setup.configurator.depositCallback() ==
                    address(setup.defaultBondStrategy)
            );
            require(setup.configurator.withdrawalCallback() == address(0));
            require(setup.configurator.withdrawalFeeD9() == 0);
            require(
                setup.configurator.maximalTotalSupply() ==
                    deployParams.maximalTotalSupply
            );
            require(setup.configurator.isDepositLocked() == false);
            require(setup.configurator.areTransfersLocked() == false);
            require(
                setup.configurator.ratiosOracle() ==
                    address(deployParams.ratiosOracle)
            );
            require(
                setup.configurator.priceOracle() ==
                    address(deployParams.priceOracle)
            );
            require(setup.configurator.validator() == address(setup.validator));
            require(
                setup.configurator.isDelegateModuleApproved(
                    address(deployParams.defaultBondModule)
                ) == true
            );

            require(setup.configurator.vault() == address(setup.vault));
        }

        // DefaultBondStrategy values
        {
            require(
                address(setup.defaultBondStrategy.bondModule()) ==
                    address(deployParams.defaultBondModule)
            );
            require(
                address(setup.defaultBondStrategy.erc20TvlModule()) ==
                    address(deployParams.erc20TvlModule)
            );
            require(
                address(setup.defaultBondStrategy.vault()) ==
                    address(setup.vault)
            );

            bytes memory tokenToDataBytes = setup
                .defaultBondStrategy
                .tokenToData(deployParams.wsteth);
            require(tokenToDataBytes.length != 0);
            IDefaultBondStrategy.Data[] memory data = abi.decode(
                tokenToDataBytes,
                (IDefaultBondStrategy.Data[])
            );
            require(data.length == 1);
            require(data[0].bond == deployParams.wstethDefaultBond);
            require(data[0].ratioX96 == DeployConstants.Q96);
            require(
                IDefaultCollateralFactory(deployParams.wstethDefaultBondFactory)
                    .isEntity(data[0].bond)
            );
        }

        // ConstantsAggregatorV3 values:
        {
            require(
                ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
                    .decimals() == 18
            );
            require(
                ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
                    .answer() == 1 ether
            );

            (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
                    .latestRoundData();
            require(roundId == 0);
            require(answer == 1 ether);
            require(startedAt == block.timestamp);
            require(updatedAt == block.timestamp);
            require(answeredInRound == 0);
        }

        // WStethRatiosAggregatorV3 values:
        {
            require(
                WStethRatiosAggregatorV3(
                    address(deployParams.wstethAggregatorV3)
                ).decimals() == 18
            );

            require(
                WStethRatiosAggregatorV3(
                    address(deployParams.wstethAggregatorV3)
                ).wsteth() == deployParams.wsteth
            );

            (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = WStethRatiosAggregatorV3(
                    address(deployParams.wstethAggregatorV3)
                ).latestRoundData();
            require(roundId == 0);
            require(
                answer ==
                    int256(
                        IWSteth(deployParams.wsteth).getStETHByWstETH(1 ether)
                    )
            );
            require(startedAt == block.timestamp);
            require(updatedAt == block.timestamp);
            require(answeredInRound == 0);
        }

        // ChainlinkOracle values:
        {
            require(
                deployParams.priceOracle.baseTokens(address(setup.vault)) ==
                    deployParams.weth
            );

            require(
                deployParams
                    .priceOracle
                    .aggregatorsData(address(setup.vault), deployParams.weth)
                    .aggregatorV3 == address(deployParams.wethAggregatorV3)
            );
            require(
                deployParams
                    .priceOracle
                    .aggregatorsData(address(setup.vault), deployParams.weth)
                    .maxAge == 0
            );
            require(
                deployParams
                    .priceOracle
                    .aggregatorsData(address(setup.vault), deployParams.wsteth)
                    .aggregatorV3 == address(deployParams.wstethAggregatorV3)
            );
            require(
                deployParams
                    .priceOracle
                    .aggregatorsData(address(setup.vault), deployParams.wsteth)
                    .maxAge == 0
            );

            require(
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.weth
                ) == DeployConstants.Q96
            );

            require(
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ) ==
                    (IWSteth(deployParams.wsteth).getStETHByWstETH(1 ether) *
                        DeployConstants.Q96) /
                        1 ether
            );
        }
    }
}
