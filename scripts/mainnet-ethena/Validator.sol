// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

abstract contract Validator {
    /*
        validationFlagsBits:
        0 - mainnet test deployment (the vault has an additional actor with the admin delegate role)
        1 - immediately after deployment
    */
    function validateParameters(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup,
        uint8 validationFlags
    ) public view {
        // vault permissions

        bytes32 ADMIN_ROLE = keccak256("admin");
        bytes32 ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
        bytes32 OPERATOR_ROLE = keccak256("operator");

        uint256 ADMIN_ROLE_MASK = 1 << 255;
        uint256 DEPOSITOR_ROLE_MASK = 1 << 0;
        uint256 DEFAULT_BOND_STRATEGY_ROLE_MASK = 1 << 1;
        uint256 DEFAULT_BOND_MODULE_ROLE_MASK = 1 << 2;

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
            if (validationFlags & 1 == 0) {
                require(
                    vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 0,
                    "Wrong admin delegate count"
                );
            } else {
                // ignore future validation
                // only for testing
                require(
                    vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 1,
                    "Wrong admin delegate count"
                );
            }
            require(
                vault.getRoleMemberCount(OPERATOR_ROLE) == 1,
                "OPERATOR_ROLE count is not equal to 1"
            );
            require(
                vault.hasRole(
                    OPERATOR_ROLE,
                    address(setup.defaultBondStrategy)
                ),
                "DefaultBondStrategy has no OPERATOR_ROLE"
            );
        }

        // DefaultBondStrategy permissions
        {
            DefaultBondStrategy strategy = setup.defaultBondStrategy;
            require(
                strategy.getRoleMemberCount(ADMIN_ROLE) == 1,
                "Admin not set"
            );
            require(
                strategy.hasRole(ADMIN_ROLE, deployParams.admin),
                "DefaultBondStrategy: admin has no ADMIN_ROLE"
            );
            require(
                strategy.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 0,
                "DefaultBondStrategy: more than one has ADMIN_DELEGATE_ROLE"
            );
            require(
                strategy.getRoleMemberCount(OPERATOR_ROLE) == deployParams.curators.length,
                "DefaultBondStrategy: OPERATOR_ROLE count is not equal to 1"
            );
            
            for (uint256 i = 0; i < deployParams.curators.length; i++) {
                require(
                    strategy.hasRole(OPERATOR_ROLE, deployParams.curators[i]),
                    "DefaultBondStrategy: curator has no OPERATOR_ROLE"
                );
            }
        }

        // Managed validator permissions
        {
            ManagedValidator validator = setup.validator;
            require(
                validator.publicRoles() == DEPOSITOR_ROLE_MASK,
                "DEPOSITOR_ROLE_MASK mismatch"
            );

            require(
                validator.userRoles(deployParams.deployer) == 0,
                "Deployer has roles"
            );
            require(
                validator.userRoles(deployParams.admin) == ADMIN_ROLE_MASK,
                "Admin has no roles"
            );
            for (uint256 i = 0; i < deployParams.curators.length; i++) {
                require(
                    validator.userRoles(deployParams.curators[i]) == 0,
                    "Curator has roles"
                );
            }
            require(
                validator.userRoles(address(setup.defaultBondStrategy)) ==
                    DEFAULT_BOND_STRATEGY_ROLE_MASK,
                "DEFAULT_BOND_STRATEGY_ROLE_MASK mismatch"
            );
            require(
                validator.userRoles(address(setup.vault)) ==
                    DEFAULT_BOND_MODULE_ROLE_MASK,
                "DEFAULT_BOND_MODULE_ROLE_MASK mismatch"
            );

            require(
                validator.allowAllSignaturesRoles(
                    address(setup.defaultBondStrategy)
                ) == 0,
                "Invalid allowAllSignaturesRoles of DefaultBondStrategy"
            );
            require(
                validator.allowAllSignaturesRoles(address(setup.vault)) ==
                    DEFAULT_BOND_STRATEGY_ROLE_MASK,
                "Invalid allowAllSignaturesRoles of Vault"
            );
            require(
                validator.allowAllSignaturesRoles(
                    address(deployParams.defaultBondModule)
                ) == DEFAULT_BOND_MODULE_ROLE_MASK,
                "Invalid allowAllSignaturesRoles of DefaultBondModule"
            );
            require(
                validator.allowSignatureRoles(
                    address(setup.vault),
                    IVault.deposit.selector
                ) == DEPOSITOR_ROLE_MASK,
                "Invalid allowSignatureRoles of Vault"
            );
        }

        // Vault balances
        if (validationFlags & 2 == 0) {
            require(
                setup.vault.balanceOf(deployParams.deployer) == 0,
                "Invalid vault lp tokens balance"
            );
            require(
                setup.vault.balanceOf(address(setup.vault)) ==
                    deployParams.initialDeposit,
                "Invalid vault balance"
            );
            require(
                setup.vault.totalSupply() == deployParams.initialDeposit,
                "Invalid total supply"
            );
            if (
                IDefaultBond(deployParams.defaultBond).limit() !=
                IDefaultBond(deployParams.defaultBond).totalSupply()
            ) {
                require(
                    IERC20(deployParams.underlyingToken).balanceOf(
                        address(setup.vault)
                    ) == 0,
                    "Invalid underlyingToken balance of vault"
                );
            }
        }

        // Vault values
        {
            require(
                keccak256(bytes(setup.vault.name())) ==
                    keccak256(bytes(deployParams.lpTokenName)),
                "Wrong LP token name"
            );
            require(
                keccak256(bytes(setup.vault.symbol())) ==
                    keccak256(bytes(deployParams.lpTokenSymbol)),
                "Wrong LP token symbol"
            );
            require(setup.vault.decimals() == 18, "Invalid token decimals");

            require(
                address(setup.vault.configurator()) ==
                    address(setup.configurator),
                "Invalid configurator address"
            );
            {
                address[] memory underlyingTokens = setup
                    .vault
                    .underlyingTokens();
                require(
                    underlyingTokens.length == 1,
                    "Invalid length of underlyingTokens"
                );
                require(
                    underlyingTokens[0] == deployParams.underlyingToken,
                    "invalid underlying token"
                );
            }
            {
                address[] memory tvlModules = setup.vault.tvlModules();
                require(tvlModules.length == 2, "Invalid tvl modules count");
                require(
                    tvlModules[0] == address(deployParams.erc20TvlModule),
                    "Invalid first tvl module"
                );
                require(
                    tvlModules[1] == address(deployParams.defaultBondTvlModule),
                    "Invalid second tvl module"
                );
            }

            if (validationFlags & 2 == 0) {
                require(
                    setup
                        .vault
                        .withdrawalRequest(deployParams.deployer)
                        .lpAmount == 0,
                    "Deployer has withdrawal request"
                );

                address[] memory pendingWithdrawers = setup
                    .vault
                    .pendingWithdrawers();
                require(
                    pendingWithdrawers.length == 0,
                    "Deployer has pending withdrawal request"
                );
            }
            {
                (
                    address[] memory underlyingTvlTokens,
                    uint256[] memory underlyingTvlValues
                ) = setup.vault.underlyingTvl();
                require(
                    underlyingTvlTokens.length == 1,
                    "Invalid length of underlyingTvlTokens"
                );
                require(
                    underlyingTvlTokens[0] == deployParams.underlyingToken,
                    "invalid underlying tvl token"
                );

                require(
                    underlyingTvlValues.length == 1,
                    "Invalid length of underlyingTvlValues"
                );
            
                require(
                    underlyingTvlValues[0] == deployParams.initialDeposit,
                    "Invalid initial underlying tvl"
                );
            }

            {
                (
                    address[] memory baseTvlTokens,
                    uint256[] memory baseTvlValues
                ) = setup.vault.baseTvl();
                require(
                    baseTvlTokens.length == 2,
                    "Invalid baseTvlTokens count"
                );
                require(
                    baseTvlValues.length == 2,
                    "Invalid baseTvlValues count"
                );

                uint256 underlyingTokenIndex = deployParams.underlyingToken <
                    deployParams.defaultBond
                    ? 0
                    : 1;

                require(
                    baseTvlTokens[underlyingTokenIndex] == deployParams.underlyingToken,
                    "BaseTvlTokens is not wsteth"
                );
                require(
                    baseTvlTokens[underlyingTokenIndex ^ 1] ==
                        deployParams.defaultBond,
                    "Invalid defaultBond"
                );

                require(
                    baseTvlValues[underlyingTokenIndex] +  baseTvlValues[underlyingTokenIndex ^ 1] == deployParams.initialDeposit,
                    "Invalid initial total value"
                );

                if (
                    IDefaultBond(deployParams.defaultBond).limit() !=
                    IDefaultBond(deployParams.defaultBond).totalSupply()
                ) {
                    require(baseTvlValues[underlyingTokenIndex] == 0);
                } else {
                    require(
                        baseTvlValues[underlyingTokenIndex] == deployParams.initialDeposit
                    );
                }
            }

            {
                if (validationFlags & 2 == 0) {
                    require(
                        setup.vault.totalSupply() == deployParams.initialDeposit
                    );
                    require(setup.vault.balanceOf(deployParams.deployer) == 0);
                    require(
                        setup.vault.balanceOf(address(setup.vault)) ==
                            deployParams.initialDeposit
                    );
                }

                IVault.ProcessWithdrawalsStack memory stack = setup
                    .vault
                    .calculateStack();

                address[] memory expectedTokens = new address[](1);
                expectedTokens[0] = deployParams.underlyingToken;
                require(
                    stack.tokensHash == keccak256(abi.encode(stack.tokens)),
                    "Invalid tokens hash"
                );
                require(
                    stack.tokensHash == keccak256(abi.encode(expectedTokens)),
                    "Invalid expected tokens hash"
                );

                if (validationFlags & 2 == 0) {
                    require(
                        stack.totalSupply == deployParams.initialDeposit,
                        "Invalid total supply"
                    );
                    require(
                            stack.totalValue == deployParams.initialDeposit,
                        "Invalid total value"
                    );
                }

                require(
                    stack.ratiosX96.length == 1,
                    "Invalid ratiosX96 length"
                );
                require(
                    stack.ratiosX96[0] == DeployConstants.Q96,
                    "Invalid ratioX96 value"
                );

                require(
                    stack.erc20Balances.length == 1,
                    "Invalid erc20Balances length"
                );

                if (
                    IDefaultBond(deployParams.defaultBond).limit() !=
                    IDefaultBond(deployParams.defaultBond).totalSupply()
                ) {
                    require(
                        stack.erc20Balances[0] == 0,
                        "Invalid erc20Balances value"
                    );
                }

                require(
                    stack.ratiosX96Value == DeployConstants.Q96,
                    "Invalid ratiosX96Value"
                );
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
                .tokenToData(deployParams.underlyingToken);
            require(tokenToDataBytes.length != 0);
            IDefaultBondStrategy.Data[] memory data = abi.decode(
                tokenToDataBytes,
                (IDefaultBondStrategy.Data[])
            );
            require(data.length == 1);
            require(data[0].bond == deployParams.defaultBond);
            require(data[0].ratioX96 == DeployConstants.Q96);
            require(
                IDefaultCollateralFactory(deployParams.defaultBondFactory)
                    .isEntity(data[0].bond)
            );
        }

        // ConstantsAggregatorV3 values:
        {
            require(
                ConstantAggregatorV3(address(deployParams.constantAggregatorV3))
                    .decimals() == 18
            );
            require(
                ConstantAggregatorV3(address(deployParams.constantAggregatorV3))
                    .answer() == 1 ether
            );

            (
                uint80 roundId,
                int256 answer,
                uint256 startedAt,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = ConstantAggregatorV3(address(deployParams.constantAggregatorV3))
                    .latestRoundData();
            require(roundId == 0);
            require(answer == 1 ether);
            require(startedAt == block.timestamp);
            require(updatedAt == block.timestamp);
            require(answeredInRound == 0);
        }

        // ChainlinkOracle values:
        {
            require(
                deployParams.priceOracle.baseTokens(address(setup.vault)) ==
                    deployParams.underlyingToken
            );

            require(
                deployParams
                    .priceOracle
                    .aggregatorsData(address(setup.vault), deployParams.underlyingToken)
                    .aggregatorV3 == address(deployParams.constantAggregatorV3)
            );
            require(
                deployParams
                    .priceOracle
                    .aggregatorsData(address(setup.vault), deployParams.underlyingToken)
                    .maxAge == 0
            );

            require(
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.underlyingToken
                ) == DeployConstants.Q96
            );
        }

        // DefaultAccessControl admins
        {
            require(
                setup.vault.getRoleAdmin(setup.vault.ADMIN_ROLE()) ==
                    setup.vault.ADMIN_ROLE()
            );
            require(
                setup.vault.getRoleAdmin(setup.vault.ADMIN_DELEGATE_ROLE()) ==
                    setup.vault.ADMIN_ROLE()
            );
            require(
                setup.vault.getRoleAdmin(setup.vault.OPERATOR()) ==
                    setup.vault.ADMIN_DELEGATE_ROLE()
            );
        }
    }

    function testValidator() external pure {}
}
