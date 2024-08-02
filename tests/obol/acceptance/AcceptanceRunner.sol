// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/obol/DeployInterfaces.sol";
import "../../../scripts/obol/DeployScript.sol";

contract AcceptanceRunner {
    // Roles constants
    bytes32 internal constant ADMIN_ROLE = keccak256("admin");
    bytes32 internal constant ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
    bytes32 internal constant OPERATOR_ROLE = keccak256("operator");

    // Deployment constants
    uint256 internal constant SIMPLE_DVT_MODULE_ID = 2;

    uint8 internal constant DEPOSITOR_ROLE_BIT = 0;
    uint8 internal constant DELEGATE_CALLER_ROLE_BIT = 1;
    uint8 internal constant VAULT_ROLE_BIT = 2;
    uint8 internal constant ADMIN_ROLE_BIT = 255;

    uint256 internal constant DEPOSITOR_ROLE_MASK = 1 << DEPOSITOR_ROLE_BIT;
    uint256 internal constant DELEGATE_CALLER_ROLE_MASK =
        1 << DELEGATE_CALLER_ROLE_BIT;
    uint256 internal constant VAULT_ROLE_MASK = 1 << VAULT_ROLE_BIT;
    uint256 internal constant ADMIN_ROLE_MASK = 1 << ADMIN_ROLE_BIT;

    uint256 internal constant INITIAL_DEPOSIT_ETH = 10 gwei;
    uint256 internal constant MAXIMAL_TOTAL_SUPPLY = 10000 ether;
    uint256 internal constant MAXIMAL_ALLOWED_REMAINDER = 1 ether;

    // Flags
    bool internal HAS_IN_DEPLOYMENT_BLOCK_FLAG = false; // if true enables additional checks, that are valid only for deployment block
    bool internal HAS_TEST_PARAMETERS = false; // if true allows to use test parameters (small delays, more permissions, e.t.c)

    function _checkRolesPermissions(
        ManagedValidator validator,
        address addr,
        bool hasUserRoles,
        bool hasAllowAllSignatureRoles,
        bool hasAllowSignatureRoles
    ) private view {
        uint256 userRoles = validator.userRoles(addr);
        if (hasUserRoles) {
            require(userRoles != 0, "ManagedValidator: User roles are not set");
        } else {
            require(userRoles == 0, "ManagedValidator: User roles are set");
        }
        uint256 allowAllSignatureRoles = validator.allowAllSignaturesRoles(
            addr
        );
        if (hasAllowAllSignatureRoles) {
            require(
                allowAllSignatureRoles != 0,
                "ManagedValidator: AllowAllSignatureRoles are not set"
            );
        } else {
            require(
                allowAllSignatureRoles == 0,
                "ManagedValidator: AllowAllSignatureRoles are set"
            );
        }

        // delegateCall
        uint256 allowSignatureRoles = validator.allowSignatureRoles(
            addr,
            IVault.delegateCall.selector
        );
        if (hasAllowSignatureRoles) {
            require(
                allowSignatureRoles != 0,
                "ManagedValidator: AllowSignatureRoles are not set (delegateCall)"
            );
        } else {
            require(
                allowSignatureRoles == 0,
                "ManagedValidator: AllowSignatureRoles are set (delegateCall)"
            );
        }

        // deposit
        allowSignatureRoles = validator.allowSignatureRoles(
            addr,
            IVault.deposit.selector
        );
        if (hasAllowSignatureRoles) {
            require(
                allowSignatureRoles != 0,
                "ManagedValidator: AllowSignatureRoles are not set (deposit)"
            );
        } else {
            require(
                allowSignatureRoles == 0,
                "ManagedValidator: AllowSignatureRoles are set (deposit)"
            );
        }
    }

    function validateParameters(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup
    ) public view {
        uint256 wethIndex = deployParams.weth < deployParams.wsteth ? 0 : 1;

        // Vault permissions
        {
            Vault vault = setup.vault;
            require(
                vault.getRoleMemberCount(ADMIN_ROLE) == 1,
                "Vault: Wrong admin count"
            );
            require(
                vault.hasRole(ADMIN_ROLE, deployParams.admin),
                "Vault: Admin not set"
            );
            require(
                vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) <=
                    (HAS_TEST_PARAMETERS ? 1 : 0),
                "Vault: Wrong admin delegate count"
            );

            require(
                vault.getRoleMemberCount(OPERATOR_ROLE) <= 2,
                "Vault: OPERATOR_ROLE count is not equal to 2"
            );
            require(
                vault.hasRole(OPERATOR_ROLE, address(setup.strategy)),
                "Vault: Strategy has no OPERATOR_ROLE"
            );
            require(
                vault.hasRole(
                    OPERATOR_ROLE,
                    address(deployParams.curatorAdmin)
                ),
                "Vault: Curator admin has no OPERATOR_ROLE"
            );
        }

        // SimpleDVTStakingStrategy permissions
        {
            SimpleDVTStakingStrategy strategy = setup.strategy;
            require(
                strategy.getRoleMemberCount(ADMIN_ROLE) == 1,
                "Strategy: Admin not set"
            );
            require(
                strategy.hasRole(ADMIN_ROLE, deployParams.admin),
                "Strategy: admin has no ADMIN_ROLE"
            );
            require(
                strategy.getRoleMemberCount(ADMIN_DELEGATE_ROLE) ==
                    (HAS_TEST_PARAMETERS ? 1 : 0),
                "Strategy: more than one has ADMIN_DELEGATE_ROLE"
            );
            require(
                strategy.getRoleMemberCount(OPERATOR_ROLE) ==
                    1 + (HAS_TEST_PARAMETERS ? 1 : 0),
                "Strategy: OPERATOR_ROLE count is not equal to 1"
            );
            require(
                strategy.hasRole(OPERATOR_ROLE, deployParams.curatorOperator),
                "Strategy: curator has no OPERATOR_ROLE"
            );
        }

        // ManagedValidator permissions
        // Required roles:
        {
            ManagedValidator validator = setup.validator;

            require(
                validator.userRoles(deployParams.admin) == ADMIN_ROLE_MASK,
                "ManagedValidator: Admin roles mismatch"
            );

            require(
                validator.userRoles(address(setup.strategy)) ==
                    DELEGATE_CALLER_ROLE_MASK,
                "ManagedValidator: Strategy roles mismatch"
            );

            require(
                validator.userRoles(deployParams.curatorAdmin) ==
                    DELEGATE_CALLER_ROLE_MASK,
                "ManagedValidator: Curator admin roles mismatch"
            );

            require(
                validator.allowSignatureRoles(
                    address(setup.vault),
                    IVault.delegateCall.selector
                ) == DELEGATE_CALLER_ROLE_MASK,
                "ManagedValidator: Vault roles mismatch"
            );

            require(
                validator.userRoles(address(setup.vault)) == VAULT_ROLE_MASK,
                "ManagedValidator: Vault roles mismatch"
            );

            require(
                validator.allowAllSignaturesRoles(
                    address(deployParams.stakingModule)
                ) == VAULT_ROLE_MASK,
                "ManagedValidator: StakingModule roles mismatch"
            );

            require(
                validator.publicRoles() == DEPOSITOR_ROLE_MASK,
                "ManagedValidator: Public roles mismatch"
            );

            require(
                validator.allowSignatureRoles(
                    address(setup.vault),
                    IVault.deposit.selector
                ) == DEPOSITOR_ROLE_MASK,
                "ManagedValidator: Vault deposit roles mismatch"
            );
        }

        {
            ManagedValidator validator = setup.validator;

            {
                // Addresses without any roles
                address[19] memory forbiddenAddresses = [
                    deployParams.deployer,
                    deployParams.proxyAdmin,
                    deployParams.curatorOperator,
                    deployParams.lidoLocator,
                    deployParams.wsteth,
                    deployParams.steth,
                    deployParams.weth,
                    address(deployParams.initialImplementation),
                    address(deployParams.initializer),
                    address(deployParams.erc20TvlModule),
                    address(deployParams.ratiosOracle),
                    address(deployParams.priceOracle),
                    address(deployParams.wethAggregatorV3),
                    address(deployParams.wstethAggregatorV3),
                    address(deployParams.defaultProxyImplementation),
                    address(setup.proxyAdmin),
                    address(setup.configurator),
                    address(setup.validator),
                    address(0)
                ];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    _checkRolesPermissions(
                        validator,
                        forbiddenAddresses[i],
                        false, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                }
            }

            {
                // Addresses that have only userRoles
                address[3] memory forbiddenAddresses = [
                    deployParams.admin,
                    deployParams.curatorAdmin,
                    address(setup.strategy)
                ];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    _checkRolesPermissions(
                        validator,
                        forbiddenAddresses[i],
                        true, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                }
            }

            {
                // Addresses that have only allowAllSignaturesRoles
                address[1] memory forbiddenAddresses = [
                    address(deployParams.stakingModule)
                ];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    _checkRolesPermissions(
                        validator,
                        forbiddenAddresses[i],
                        false, // hasUserRoles
                        true, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                }
            }

            {
                // Addresses that have all roles except of allowAllSignaturesRoles
                address[1] memory forbiddenAddresses = [address(setup.vault)];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    _checkRolesPermissions(
                        validator,
                        forbiddenAddresses[i],
                        true, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        true // hasAllowSignatureRoles
                    );
                }
            }
        }

        // Vault balances
        if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
            require(
                setup.vault.balanceOf(deployParams.deployer) == 0,
                "Vault: Invalid vault lp tokens balance"
            );
            require(
                setup.vault.balanceOf(address(setup.vault)) ==
                    deployParams.initialDepositWETH,
                "Vault: Invalid vault balance"
            );
            require(
                setup.vault.totalSupply() == deployParams.initialDepositWETH,
                "Vault: Invalid total supply"
            );

            require(
                IERC20(deployParams.weth).balanceOf(address(setup.vault)) ==
                    deployParams.initialDepositWETH,
                "Vault: Invalid vault weth balance"
            );
            require(
                IERC20(deployParams.wsteth).balanceOf(address(setup.vault)) ==
                    0,
                "Vault: Invalid vault wsteth balance"
            );
        }

        // Vault values
        {
            require(
                keccak256(bytes(setup.vault.name())) ==
                    keccak256(bytes(deployParams.lpTokenName)),
                "Vault: Wrong LP token name"
            );
            require(
                keccak256(bytes(setup.vault.symbol())) ==
                    keccak256(bytes(deployParams.lpTokenSymbol)),
                "Vault: Wrong LP token symbol"
            );
            require(
                setup.vault.decimals() == 18,
                "Vault: Invalid token decimals"
            );

            require(
                address(setup.vault.configurator()) ==
                    address(setup.configurator),
                "Vault: Invalid configurator address"
            );
            {
                address[] memory underlyingTokens = setup
                    .vault
                    .underlyingTokens();
                require(
                    underlyingTokens.length == 2,
                    "Vault: Invalid length of underlyingTokens"
                );
                require(
                    underlyingTokens[wethIndex] == deployParams.weth,
                    "Vault: Underlying token is not weth"
                );
                require(
                    underlyingTokens[wethIndex ^ 1] == deployParams.wsteth,
                    "Vault: Underlying token is not wsteth"
                );
            }
            {
                address[] memory tvlModules = setup.vault.tvlModules();
                require(tvlModules.length == 1, "Invalid tvl modules count");
                require(
                    tvlModules[0] == address(deployParams.erc20TvlModule),
                    "Vault: Invalid first tvl module"
                );
            }

            if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
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
                    underlyingTvlTokens.length == 2,
                    "Vault: Invalid length of underlyingTvlTokens"
                );
                require(
                    underlyingTvlTokens[wethIndex] == deployParams.weth,
                    "Vault: Underlying tvl token is not wsteth"
                );
                require(
                    underlyingTvlTokens[wethIndex ^ 1] == deployParams.wsteth,
                    "Vault: Underlying tvl token is not wsteth"
                );

                require(
                    underlyingTvlValues.length == 2,
                    "Vault: Invalid length of underlyingTvlValues"
                );

                if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
                    require(
                        underlyingTvlValues[wethIndex] == INITIAL_DEPOSIT_ETH,
                        "Vault: Invalid weth tvl value"
                    );
                    require(
                        underlyingTvlValues[wethIndex ^ 1] == 0,
                        "Vault: Invalid wsteth tvl value"
                    );
                }

                (
                    address[] memory baseTvlTokens,
                    uint256[] memory baseTvlValues
                ) = setup.vault.baseTvl();
                require(
                    baseTvlTokens.length == 2,
                    "Vault: Invalid baseTvlTokens count"
                );
                require(
                    baseTvlValues.length == 2,
                    "Vault: Invalid baseTvlValues count"
                );

                require(
                    keccak256(abi.encode(baseTvlTokens)) ==
                        keccak256(abi.encode(underlyingTvlTokens)),
                    "Vault: Invalid baseTvlTokens"
                );

                require(
                    keccak256(abi.encode(baseTvlValues)) ==
                        keccak256(abi.encode(underlyingTvlValues)),
                    "Vault: Invalid baseTvlValues"
                );
            }

            {
                if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
                    require(setup.vault.totalSupply() == INITIAL_DEPOSIT_ETH);
                    require(
                        setup.vault.balanceOf(address(setup.vault)) ==
                            INITIAL_DEPOSIT_ETH,
                        "Vault: Invalid vault balance"
                    );
                    require(
                        setup.vault.balanceOf(deployParams.deployer) == 0,
                        "Vault: Invalid deployer balance"
                    );
                }

                IVault.ProcessWithdrawalsStack memory stack = setup
                    .vault
                    .calculateStack();

                address[] memory expectedTokens = new address[](2);
                expectedTokens[wethIndex] = deployParams.weth;
                expectedTokens[wethIndex ^ 1] = deployParams.wsteth;
                require(
                    stack.tokensHash == keccak256(abi.encode(stack.tokens)),
                    "Vault.calculateStack: Invalid tokens hash"
                );
                require(
                    stack.tokensHash == keccak256(abi.encode(expectedTokens)),
                    "Vault.calculateStack: Invalid expected tokens hash"
                );

                if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
                    require(
                        stack.totalSupply == deployParams.initialDepositWETH,
                        "Vault.calculateStack: Invalid total supply"
                    );
                    require(
                        stack.totalValue == deployParams.initialDepositWETH,
                        "Vault.calculateStack: Invalid total value"
                    );
                }

                require(
                    stack.ratiosX96.length == 2,
                    "Vault.calculateStack: Invalid ratiosX96 length"
                );

                require(
                    stack.ratiosX96[wethIndex] == 0,
                    "Vault.calculateStack: Invalid withdrawal weth ratio"
                );
                require(
                    stack.ratiosX96[wethIndex ^ 1] == DeployConstants.Q96,
                    "Vault.calculateStack: Invalid withdrawal wsteth ratio"
                );

                require(
                    stack.erc20Balances.length == 2,
                    "Vault.calculateStack: Invalid erc20Balances length"
                );

                if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
                    require(
                        stack.erc20Balances[wethIndex] ==
                            deployParams.initialDepositWETH,
                        "Vault.calculateStack: Invalid erc20Balances value"
                    );
                    require(
                        stack.erc20Balances[wethIndex ^ 1] == 0,
                        "Vault.calculateStack: Invalid erc20Balances value"
                    );
                }

                uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
                    .getStETHByWstETH(DeployConstants.Q96);
                require(
                    stack.ratiosX96Value > 0 &&
                        stack.ratiosX96Value <= expectedStethAmount,
                    "Invalid ratiosX96Value"
                );
                require(
                    (expectedStethAmount - stack.ratiosX96Value) <
                        stack.ratiosX96Value / 1e18,
                    "Invalid ratiosX96Value"
                );

                require(
                    stack.timestamp == block.timestamp,
                    "Invalid timestamp"
                );
                require(stack.feeD9 == 0, "Invalid feeD9");
            }

            // VaultConfigurator values
            if (!HAS_TEST_PARAMETERS) {
                require(
                    setup.configurator.baseDelay() == 30 days,
                    "VaultConfigurator: baseDelay is not 30 days"
                );
                require(
                    setup.configurator.depositCallbackDelay() == 1 days,
                    "VaultConfigurator: depositCallbackDelay is not 1 day"
                );
                require(
                    setup.configurator.withdrawalCallbackDelay() == 1 days,
                    "VaultConfigurator: withdrawalCallbackDelay is not 1 day"
                );
                require(
                    setup.configurator.withdrawalFeeD9Delay() == 30 days,
                    "VaultConfigurator: withdrawalFeeD9Delay is not 30 days"
                );
                require(
                    setup.configurator.maximalTotalSupplyDelay() == 4 hours,
                    "VaultConfigurator: maximalTotalSupplyDelay is not 4 hours"
                );
                require(
                    setup.configurator.isDepositLockedDelay() == 1 hours,
                    "VaultConfigurator: isDepositLockedDelay is not 1 hour"
                );
                require(
                    setup.configurator.areTransfersLockedDelay() == 365 days,
                    "VaultConfigurator: areTransfersLockedDelay is not 365 days"
                );
                require(
                    setup.configurator.delegateModuleApprovalDelay() == 1 days,
                    "VaultConfigurator: delegateModuleApprovalDelay is not 1 day"
                );
                require(
                    setup.configurator.ratiosOracleDelay() == 30 days,
                    "VaultConfigurator: ratiosOracleDelay is not 30 days"
                );
                require(
                    setup.configurator.priceOracleDelay() == 30 days,
                    "VaultConfigurator: priceOracleDelay is not 30 days"
                );
                require(
                    setup.configurator.validatorDelay() == 30 days,
                    "VaultConfigurator: validatorDelay is not 30 days"
                );
                require(
                    setup.configurator.emergencyWithdrawalDelay() == 90 days,
                    "VaultConfigurator: emergencyWithdrawalDelay is not 90 days"
                );
                require(
                    setup.configurator.depositCallback() == address(0),
                    "VaultConfigurator: depositCallback is not 0"
                );
                require(
                    setup.configurator.withdrawalCallback() == address(0),
                    "VaultConfigurator: withdrawalCallback is not 0"
                );
                require(
                    setup.configurator.withdrawalFeeD9() == 0,
                    "VaultConfigurator: withdrawalFeeD9 is not 0"
                );
                require(
                    setup.configurator.maximalTotalSupply() ==
                        deployParams.maximalTotalSupply,
                    "VaultConfigurator: maximalTotalSupply is not equal to deployParams.maximalTotalSupply"
                );
                require(
                    setup.configurator.isDepositLocked() == false,
                    "VaultConfigurator: isDepositLocked is not false"
                );
                require(
                    setup.configurator.areTransfersLocked() == false,
                    "VaultConfigurator: areTransfersLocked is not false"
                );
                require(
                    setup.configurator.ratiosOracle() ==
                        address(deployParams.ratiosOracle),
                    "VaultConfigurator: ratiosOracle is not equal to deployParams.ratiosOracle"
                );
                require(
                    setup.configurator.priceOracle() ==
                        address(deployParams.priceOracle),
                    "VaultConfigurator: priceOracle is not equal to deployParams.priceOracle"
                );
                require(
                    setup.configurator.validator() == address(setup.validator),
                    "VaultConfigurator: validator is not equal to setup.validator"
                );
                require(
                    setup.configurator.isDelegateModuleApproved(
                        address(deployParams.stakingModule)
                    ) == true,
                    "VaultConfigurator: stakingModule is not approved"
                );

                require(
                    setup.configurator.vault() == address(setup.vault),
                    "VaultConfigurator: vault is not equal to setup.vault"
                );
            }

            // SimpleDVTStakingStrategy values
            {
                require(
                    address(setup.strategy.stakingModule()) ==
                        address(deployParams.stakingModule),
                    "SimpleDVTStakingStrategy: stakingModule is not equal to deployParams.stakingModule"
                );
                if (HAS_IN_DEPLOYMENT_BLOCK_FLAG) {
                    // might be changed by setMaxAllowedRemainder
                    require(
                        setup.strategy.maxAllowedRemainder() ==
                            deployParams.maximalAllowedRemainder,
                        "SimpleDVTStakingStrategy: maxAllowedRemainder is not equal to deployParams.maximalAllowedRemainder"
                    );
                }
                require(
                    address(setup.strategy.vault()) == address(setup.vault),
                    "SimpleDVTStakingStrategy: vault is not equal to setup.vault"
                );
            }

            // ConstantsAggregatorV3 values:
            {
                require(
                    ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
                        .decimals() == 18,
                    "ConstantAggregatorV3: Invalid decimals"
                );
                require(
                    ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
                        .answer() == 1 ether,
                    "ConstantAggregatorV3: Invalid answer"
                );

                (
                    uint80 roundId,
                    int256 answer,
                    uint256 startedAt,
                    uint256 updatedAt,
                    uint80 answeredInRound
                ) = ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
                        .latestRoundData();
                require(roundId == 0, "ConstantAggregatorV3: Invalid roundId");
                require(
                    answer == 1 ether,
                    "ConstantAggregatorV3: Invalid answer"
                );
                require(
                    startedAt == block.timestamp,
                    "ConstantAggregatorV3: Invalid startedAt"
                );
                require(
                    updatedAt == block.timestamp,
                    "ConstantAggregatorV3: Invalid updatedAt"
                );
                require(
                    answeredInRound == 0,
                    "ConstantAggregatorV3: Invalid answeredInRound"
                );
            }

            // WStethRatiosAggregatorV3 values:
            {
                require(
                    WStethRatiosAggregatorV3(
                        address(deployParams.wstethAggregatorV3)
                    ).decimals() == 18,
                    "WStethRatiosAggregatorV3: Invalid decimals"
                );

                require(
                    WStethRatiosAggregatorV3(
                        address(deployParams.wstethAggregatorV3)
                    ).wsteth() == deployParams.wsteth,
                    "WStethRatiosAggregatorV3: Invalid wsteth address"
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
                require(
                    roundId == 0,
                    "WStethRatiosAggregatorV3: Invalid roundId"
                );
                require(
                    answer ==
                        int256(
                            IWSteth(deployParams.wsteth).getStETHByWstETH(
                                1 ether
                            )
                        ),
                    "WStethRatiosAggregatorV3: Invalid answer"
                );
                require(
                    startedAt == block.timestamp,
                    "WStethRatiosAggregatorV3: Invalid startedAt"
                );
                require(
                    updatedAt == block.timestamp,
                    "WStethRatiosAggregatorV3: Invalid updatedAt"
                );
                require(answeredInRound == 0);
            }

            // ChainlinkOracle values:
            {
                require(
                    deployParams.priceOracle.baseTokens(address(setup.vault)) ==
                        deployParams.weth,
                    "ChainlinkOracle: Invalid baseTokens"
                );

                require(
                    deployParams
                        .priceOracle
                        .aggregatorsData(
                            address(setup.vault),
                            deployParams.weth
                        )
                        .aggregatorV3 == address(deployParams.wethAggregatorV3),
                    "ChainlinkOracle: Invalid weth aggregatorV3"
                );
                require(
                    deployParams
                        .priceOracle
                        .aggregatorsData(
                            address(setup.vault),
                            deployParams.weth
                        )
                        .maxAge == 0,
                    "ChainlinkOracle: Invalid weth maxAge"
                );
                require(
                    deployParams
                        .priceOracle
                        .aggregatorsData(
                            address(setup.vault),
                            deployParams.wsteth
                        )
                        .aggregatorV3 ==
                        address(deployParams.wstethAggregatorV3),
                    "ChainlinkOracle: Invalid wsteth aggregatorV3"
                );
                require(
                    deployParams
                        .priceOracle
                        .aggregatorsData(
                            address(setup.vault),
                            deployParams.wsteth
                        )
                        .maxAge == 0,
                    "ChainlinkOracle: Invalid wsteth maxAge"
                );

                require(
                    deployParams.priceOracle.priceX96(
                        address(setup.vault),
                        deployParams.weth
                    ) == DeployConstants.Q96,
                    "ChainlinkOracle: Invalid weth priceX96"
                );

                require(
                    deployParams.priceOracle.priceX96(
                        address(setup.vault),
                        deployParams.wsteth
                    ) ==
                        (IWSteth(deployParams.wsteth).getStETHByWstETH(
                            1 ether
                        ) * DeployConstants.Q96) /
                            1 ether,
                    "ChainlinkOracle: Invalid wsteth priceX96"
                );
            }

            // DefaultAccessControl admins
            {
                require(
                    setup.vault.getRoleAdmin(setup.vault.ADMIN_ROLE()) ==
                        setup.vault.ADMIN_ROLE(),
                    "Vault permissions: ADMIN_ROLE admin is not ADMIN_ROLE"
                );
                require(
                    setup.vault.getRoleAdmin(
                        setup.vault.ADMIN_DELEGATE_ROLE()
                    ) == setup.vault.ADMIN_ROLE(),
                    "Vault permissions: ADMIN_DELEGATE_ROLE admin is not ADMIN_ROLE"
                );
                require(
                    setup.vault.getRoleAdmin(setup.vault.OPERATOR()) ==
                        setup.vault.ADMIN_DELEGATE_ROLE(),
                    "Vault permissions: OPERATOR_ROLE admin is not ADMIN_DELEGATE_ROLE"
                );
            }

            // StakingModule parameters
            {
                StakingModule stakingModule = deployParams.stakingModule;
                require(
                    stakingModule.wsteth() == deployParams.wsteth,
                    "StakingModule: Invalid wsteth"
                );
                require(
                    stakingModule.steth() == deployParams.steth,
                    "StakingModule: Invalid steth"
                );
                require(
                    stakingModule.weth() == deployParams.weth,
                    "StakingModule: Invalid weth"
                );

                require(
                    address(stakingModule.lidoLocator()) ==
                        deployParams.lidoLocator,
                    "StakingModule: Invalid lidoLocator"
                );

                (, bytes memory response) = address(deployParams.lidoLocator)
                    .staticcall(abi.encodeWithSignature("withdrawalQueue()"));

                address withdrawalQueue = abi.decode(response, (address));
                require(
                    address(stakingModule.withdrawalQueue()) == withdrawalQueue,
                    "StakingModule: Invalid withdrawalQueue"
                );

                require(
                    stakingModule.stakingModuleId() == SIMPLE_DVT_MODULE_ID,
                    "StakingModule: stakingModuleId is not SIMPLE_DVT_MODULE_ID"
                );
            }
        }
    }
}
