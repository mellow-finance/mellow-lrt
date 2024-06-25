// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

// import "./DeployInterfaces.sol";

// abstract contract Validator {
//     /*
//         validationFlagsBits:
//         0 - mainnet test deployment (the vault has an additional actor with the admin delegate role)
//         1 - immediately after deployment
//     */
//     function validateParameters(
//         DeployInterfaces.DeployParameters memory deployParams,
//         DeployInterfaces.DeploySetup memory setup,
//         uint8 validationFlags
//     ) public view {
//         // vault permissions

//         bytes32 ADMIN_ROLE = keccak256("admin");
//         bytes32 ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
//         bytes32 OPERATOR_ROLE = keccak256("operator");

//         uint256 ADMIN_ROLE_MASK = 1 << 255;
//         uint256 DEPOSITOR_ROLE_MASK = 1 << 0;
//         uint256 DEFAULT_BOND_STRATEGY_ROLE_MASK = 1 << 1;
//         uint256 DEFAULT_BOND_MODULE_ROLE_MASK = 1 << 2;

//         // Vault permissions
//         {
//             Vault vault = setup.vault;
//             require(
//                 vault.getRoleMemberCount(ADMIN_ROLE) == 1,
//                 "Wrong admin count"
//             );
//             require(
//                 vault.hasRole(ADMIN_ROLE, deployParams.admin),
//                 "Admin not set"
//             );
//             if (validationFlags & 1 == 0) {
//                 require(
//                     vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 0,
//                     "Wrong admin delegate count"
//                 );
//             } else {
//                 // ignore future validation
//                 // only for testing
//                 require(
//                     vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 1,
//                     "Wrong admin delegate count"
//                 );
//             }
//             require(
//                 vault.getRoleMemberCount(OPERATOR_ROLE) == 1,
//                 "OPERATOR_ROLE count is not equal to 1"
//             );
//             require(
//                 vault.hasRole(
//                     OPERATOR_ROLE,
//                     address(setup.defaultBondStrategy)
//                 ),
//                 "DefaultBondStrategy has no OPERATOR_ROLE"
//             );
//         }

//         // DefaultBondStrategy permissions
//         {
//             DefaultBondStrategy strategy = setup.defaultBondStrategy;
//             require(
//                 strategy.getRoleMemberCount(ADMIN_ROLE) == 1,
//                 "Admin not set"
//             );
//             require(
//                 strategy.hasRole(ADMIN_ROLE, deployParams.admin),
//                 "DefaultBondStrategy: admin has no ADMIN_ROLE"
//             );
//             require(
//                 strategy.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 0,
//                 "DefaultBondStrategy: more than one has ADMIN_DELEGATE_ROLE"
//             );
//             require(
//                 strategy.getRoleMemberCount(OPERATOR_ROLE) == 1,
//                 "DefaultBondStrategy: OPERATOR_ROLE count is not equal to 1"
//             );
//             require(
//                 strategy.hasRole(OPERATOR_ROLE, deployParams.curator),
//                 "DefaultBondStrategy: curator has no OPERATOR_ROLE"
//             );
//         }

//         // Managed validator permissions
//         {
//             ManagedValidator validator = setup.validator;
//             require(
//                 validator.publicRoles() == DEPOSITOR_ROLE_MASK,
//                 "DEPOSITOR_ROLE_MASK mismatch"
//             );

//             require(
//                 validator.userRoles(deployParams.deployer) == 0,
//                 "Deployer has roles"
//             );
//             require(
//                 validator.userRoles(deployParams.admin) == ADMIN_ROLE_MASK,
//                 "Admin has no roles"
//             );
//             if (deployParams.curator != deployParams.admin) {
//                 require(
//                     validator.userRoles(deployParams.curator) == 0,
//                     "Curator has roles"
//                 );
//             }
//             require(
//                 validator.userRoles(address(setup.defaultBondStrategy)) ==
//                     DEFAULT_BOND_STRATEGY_ROLE_MASK,
//                 "DEFAULT_BOND_STRATEGY_ROLE_MASK mismatch"
//             );
//             require(
//                 validator.userRoles(address(setup.vault)) ==
//                     DEFAULT_BOND_MODULE_ROLE_MASK,
//                 "DEFAULT_BOND_MODULE_ROLE_MASK mismatch"
//             );

//             require(
//                 validator.allowAllSignaturesRoles(
//                     address(setup.defaultBondStrategy)
//                 ) == 0,
//                 "Invalid allowAllSignaturesRoles of DefaultBondStrategy"
//             );
//             require(
//                 validator.allowAllSignaturesRoles(address(setup.vault)) ==
//                     DEFAULT_BOND_STRATEGY_ROLE_MASK,
//                 "Invalid allowAllSignaturesRoles of Vault"
//             );
//             require(
//                 validator.allowAllSignaturesRoles(
//                     address(deployParams.defaultBondModule)
//                 ) == DEFAULT_BOND_MODULE_ROLE_MASK,
//                 "Invalid allowAllSignaturesRoles of DefaultBondModule"
//             );
//             require(
//                 validator.allowSignatureRoles(
//                     address(setup.vault),
//                     IVault.deposit.selector
//                 ) == DEPOSITOR_ROLE_MASK,
//                 "Invalid allowSignatureRoles of Vault"
//             );
//         }

//         // Vault balances
//         if (validationFlags & 2 == 0) {
//             require(
//                 setup.vault.balanceOf(deployParams.deployer) == 0,
//                 "Invalid vault lp tokens balance"
//             );
//             require(
//                 setup.vault.balanceOf(address(setup.vault)) ==
//                     setup.wstethAmountDeposited,
//                 "Invalid vault balance"
//             );
//             require(
//                 setup.vault.totalSupply() == setup.wstethAmountDeposited,
//                 "Invalid total supply"
//             );
//             if (
//                 IDefaultBond(deployParams.wstethDefaultBond).limit() !=
//                 IDefaultBond(deployParams.wstethDefaultBond).totalSupply()
//             ) {
//                 require(
//                     IERC20(deployParams.wsteth).balanceOf(
//                         address(setup.vault)
//                     ) == 0,
//                     "Invalid wsteth balance of vault"
//                 );
//             }
//             uint256 fullWstethBalance = IERC20(deployParams.wstethDefaultBond)
//                 .balanceOf(address(setup.vault)) +
//                 IERC20(deployParams.wsteth).balanceOf(address(setup.vault));
//             require(
//                 fullWstethBalance == setup.wstethAmountDeposited,
//                 "Invalid fullWstethBalance balance"
//             );
//             if (
//                 IDefaultBond(deployParams.wstethDefaultBond).limit() !=
//                 IDefaultBond(deployParams.wstethDefaultBond).totalSupply()
//             ) {
//                 require(
//                     IERC20(deployParams.wsteth).balanceOf(
//                         deployParams.wstethDefaultBond
//                     ) >= fullWstethBalance,
//                     "Invalid wsteth balance of bond"
//                 );
//             }
//             uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
//                 .getStETHByWstETH(fullWstethBalance);
//             // at most 2 weis loss due to eth->steth && steth->wsteth conversions
//             if (validationFlags & 2 == 0) {
//                 require(
//                     deployParams.initialDepositETH - 2 wei <=
//                         expectedStethAmount &&
//                         expectedStethAmount <= deployParams.initialDepositETH,
//                     "Invalid steth amount"
//                 );
//             }
//         }

//         // Vault values
//         {
//             require(
//                 keccak256(bytes(setup.vault.name())) ==
//                     keccak256(bytes(deployParams.lpTokenName)),
//                 "Wrong LP token name"
//             );
//             require(
//                 keccak256(bytes(setup.vault.symbol())) ==
//                     keccak256(bytes(deployParams.lpTokenSymbol)),
//                 "Wrong LP token symbol"
//             );
//             require(setup.vault.decimals() == 18, "Invalid token decimals");

//             require(
//                 address(setup.vault.configurator()) ==
//                     address(setup.configurator),
//                 "Invalid configurator address"
//             );
//             {
//                 address[] memory underlyingTokens = setup
//                     .vault
//                     .underlyingTokens();
//                 require(
//                     underlyingTokens.length == 1,
//                     "Invalid length of underlyingTokens"
//                 );
//                 require(
//                     underlyingTokens[0] == deployParams.wsteth,
//                     "Underlying token is not wsteth"
//                 );
//             }
//             {
//                 address[] memory tvlModules = setup.vault.tvlModules();
//                 require(tvlModules.length == 2, "Invalid tvl modules count");
//                 require(
//                     tvlModules[0] == address(deployParams.erc20TvlModule),
//                     "Invalid first tvl module"
//                 );
//                 require(
//                     tvlModules[1] == address(deployParams.defaultBondTvlModule),
//                     "Invalid second tvl module"
//                 );
//             }

//             if (validationFlags & 2 == 0) {
//                 require(
//                     setup
//                         .vault
//                         .withdrawalRequest(deployParams.deployer)
//                         .lpAmount == 0,
//                     "Deployer has withdrawal request"
//                 );

//                 address[] memory pendingWithdrawers = setup
//                     .vault
//                     .pendingWithdrawers();
//                 require(
//                     pendingWithdrawers.length == 0,
//                     "Deployer has pending withdrawal request"
//                 );
//             }
//             {
//                 (
//                     address[] memory underlyingTvlTokens,
//                     uint256[] memory underlyingTvlValues
//                 ) = setup.vault.underlyingTvl();
//                 require(
//                     underlyingTvlTokens.length == 1,
//                     "Invalid length of underlyingTvlTokens"
//                 );
//                 require(
//                     underlyingTvlTokens[0] == deployParams.wsteth,
//                     "Underlying tvl token is not wsteth"
//                 );

//                 require(
//                     underlyingTvlValues.length == 1,
//                     "Invalid length of underlyingTvlValues"
//                 );
//                 uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
//                     .getStETHByWstETH(underlyingTvlValues[0]);
//                 // valid only for tests or right after deployment
//                 // after that getStETHByWstETH will return different ratios due to rebase logic
//                 if (validationFlags & 2 == 0) {
//                     require(
//                         deployParams.initialDepositETH - 2 wei <=
//                             expectedStethAmount &&
//                             expectedStethAmount <=
//                             deployParams.initialDepositETH,
//                         "Invalid initialDepositETH"
//                     );
//                 }
//             }

//             {
//                 (
//                     address[] memory baseTvlTokens,
//                     uint256[] memory baseTvlValues
//                 ) = setup.vault.baseTvl();
//                 require(
//                     baseTvlTokens.length == 2,
//                     "Invalid baseTvlTokens count"
//                 );
//                 require(
//                     baseTvlValues.length == 2,
//                     "Invalid baseTvlValues count"
//                 );

//                 uint256 wstethIndex = deployParams.wsteth <
//                     deployParams.wstethDefaultBond
//                     ? 0
//                     : 1;

//                 require(
//                     baseTvlTokens[wstethIndex] == deployParams.wsteth,
//                     "BaseTvlTokens is not wsteth"
//                 );
//                 require(
//                     baseTvlTokens[wstethIndex ^ 1] ==
//                         deployParams.wstethDefaultBond,
//                     "Invalid wstethDefaultBond"
//                 );

//                 if (
//                     IDefaultBond(deployParams.wstethDefaultBond).limit() !=
//                     IDefaultBond(deployParams.wstethDefaultBond).totalSupply()
//                 ) {
//                     require(baseTvlValues[wstethIndex] == 0);
//                 }

//                 uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
//                     .getStETHByWstETH(
//                         baseTvlValues[wstethIndex] +
//                             baseTvlValues[wstethIndex ^ 1]
//                     );
//                 // valid only for tests or right after deployment
//                 // after that getStETHByWstETH will return different ratios due to rebase logic
//                 if (validationFlags & 2 == 0) {
//                     require(
//                         deployParams.initialDepositETH - 2 wei <=
//                             expectedStethAmount &&
//                             expectedStethAmount <=
//                             deployParams.initialDepositETH
//                     );
//                 }
//             }

//             {
//                 if (validationFlags & 2 == 0) {
//                     require(
//                         setup.vault.totalSupply() == setup.wstethAmountDeposited
//                     );
//                     require(setup.vault.balanceOf(deployParams.deployer) == 0);
//                     require(
//                         setup.vault.balanceOf(address(setup.vault)) ==
//                             setup.wstethAmountDeposited
//                     );
//                 }

//                 IVault.ProcessWithdrawalsStack memory stack = setup
//                     .vault
//                     .calculateStack();

//                 address[] memory expectedTokens = new address[](1);
//                 expectedTokens[0] = deployParams.wsteth;
//                 require(
//                     stack.tokensHash == keccak256(abi.encode(stack.tokens)),
//                     "Invalid tokens hash"
//                 );
//                 require(
//                     stack.tokensHash == keccak256(abi.encode(expectedTokens)),
//                     "Invalid expected tokens hash"
//                 );

//                 if (validationFlags & 2 == 0) {
//                     require(
//                         stack.totalSupply == setup.wstethAmountDeposited,
//                         "Invalid total supply"
//                     );
//                     require(
//                         deployParams.initialDepositETH - 2 wei <=
//                             stack.totalValue &&
//                             stack.totalValue <= deployParams.initialDepositETH,
//                         "Invalid total value"
//                     );
//                 }

//                 require(
//                     stack.ratiosX96.length == 1,
//                     "Invalid ratiosX96 length"
//                 );
//                 require(
//                     stack.ratiosX96[0] == DeployConstants.Q96,
//                     "Invalid ratioX96 value"
//                 );

//                 require(
//                     stack.erc20Balances.length == 1,
//                     "Invalid erc20Balances length"
//                 );

//                 if (
//                     IDefaultBond(deployParams.wstethDefaultBond).limit() !=
//                     IDefaultBond(deployParams.wstethDefaultBond).totalSupply()
//                 ) {
//                     require(
//                         stack.erc20Balances[0] == 0,
//                         "Invalid erc20Balances value"
//                     );
//                 }

//                 uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
//                     .getStETHByWstETH(DeployConstants.Q96);
//                 require(
//                     stack.ratiosX96Value > 0 &&
//                         stack.ratiosX96Value <= expectedStethAmount,
//                     "Invalid ratiosX96Value"
//                 );
//                 require(
//                     (expectedStethAmount - stack.ratiosX96Value) <
//                         stack.ratiosX96Value / 1e10,
//                     "Invalid ratiosX96Value"
//                 );

//                 require(
//                     stack.timestamp == block.timestamp,
//                     "Invalid timestamp"
//                 );
//                 require(stack.feeD9 == 0, "Invalid feeD9");
//             }
//         }

//         // VaultConfigurator values
//         {
//             require(setup.configurator.baseDelay() == 30 days);
//             require(setup.configurator.depositCallbackDelay() == 1 days);
//             require(setup.configurator.withdrawalCallbackDelay() == 1 days);
//             require(setup.configurator.withdrawalFeeD9Delay() == 30 days);
//             require(setup.configurator.maximalTotalSupplyDelay() == 1 days);
//             require(setup.configurator.isDepositLockedDelay() == 1 hours);
//             require(setup.configurator.areTransfersLockedDelay() == 365 days);
//             require(setup.configurator.delegateModuleApprovalDelay() == 1 days);
//             require(setup.configurator.ratiosOracleDelay() == 30 days);
//             require(setup.configurator.priceOracleDelay() == 30 days);
//             require(setup.configurator.validatorDelay() == 30 days);
//             require(setup.configurator.emergencyWithdrawalDelay() == 90 days);
//             require(
//                 setup.configurator.depositCallback() ==
//                     address(setup.defaultBondStrategy)
//             );
//             require(setup.configurator.withdrawalCallback() == address(0));
//             require(setup.configurator.withdrawalFeeD9() == 0);
//             require(
//                 setup.configurator.maximalTotalSupply() ==
//                     deployParams.maximalTotalSupply
//             );
//             require(setup.configurator.isDepositLocked() == false);
//             require(setup.configurator.areTransfersLocked() == false);
//             require(
//                 setup.configurator.ratiosOracle() ==
//                     address(deployParams.ratiosOracle)
//             );
//             require(
//                 setup.configurator.priceOracle() ==
//                     address(deployParams.priceOracle)
//             );
//             require(setup.configurator.validator() == address(setup.validator));
//             require(
//                 setup.configurator.isDelegateModuleApproved(
//                     address(deployParams.defaultBondModule)
//                 ) == true
//             );

//             require(setup.configurator.vault() == address(setup.vault));
//         }

//         // DefaultBondStrategy values
//         {
//             require(
//                 address(setup.defaultBondStrategy.bondModule()) ==
//                     address(deployParams.defaultBondModule)
//             );
//             require(
//                 address(setup.defaultBondStrategy.erc20TvlModule()) ==
//                     address(deployParams.erc20TvlModule)
//             );
//             require(
//                 address(setup.defaultBondStrategy.vault()) ==
//                     address(setup.vault)
//             );

//             bytes memory tokenToDataBytes = setup
//                 .defaultBondStrategy
//                 .tokenToData(deployParams.wsteth);
//             require(tokenToDataBytes.length != 0);
//             IDefaultBondStrategy.Data[] memory data = abi.decode(
//                 tokenToDataBytes,
//                 (IDefaultBondStrategy.Data[])
//             );
//             require(data.length == 1);
//             require(data[0].bond == deployParams.wstethDefaultBond);
//             require(data[0].ratioX96 == DeployConstants.Q96);
//             require(
//                 IDefaultCollateralFactory(deployParams.wstethDefaultBondFactory)
//                     .isEntity(data[0].bond)
//             );
//         }

//         // ConstantsAggregatorV3 values:
//         {
//             require(
//                 ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
//                     .decimals() == 18
//             );
//             require(
//                 ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
//                     .answer() == 1 ether
//             );

//             (
//                 uint80 roundId,
//                 int256 answer,
//                 uint256 startedAt,
//                 uint256 updatedAt,
//                 uint80 answeredInRound
//             ) = ConstantAggregatorV3(address(deployParams.wethAggregatorV3))
//                     .latestRoundData();
//             require(roundId == 0);
//             require(answer == 1 ether);
//             require(startedAt == block.timestamp);
//             require(updatedAt == block.timestamp);
//             require(answeredInRound == 0);
//         }

//         // WStethRatiosAggregatorV3 values:
//         {
//             require(
//                 WStethRatiosAggregatorV3(
//                     address(deployParams.wstethAggregatorV3)
//                 ).decimals() == 18
//             );

//             require(
//                 WStethRatiosAggregatorV3(
//                     address(deployParams.wstethAggregatorV3)
//                 ).wsteth() == deployParams.wsteth
//             );

//             (
//                 uint80 roundId,
//                 int256 answer,
//                 uint256 startedAt,
//                 uint256 updatedAt,
//                 uint80 answeredInRound
//             ) = WStethRatiosAggregatorV3(
//                     address(deployParams.wstethAggregatorV3)
//                 ).latestRoundData();
//             require(roundId == 0);
//             require(
//                 answer ==
//                     int256(
//                         IWSteth(deployParams.wsteth).getStETHByWstETH(1 ether)
//                     )
//             );
//             require(startedAt == block.timestamp);
//             require(updatedAt == block.timestamp);
//             require(answeredInRound == 0);
//         }

//         // ChainlinkOracle values:
//         {
//             require(
//                 deployParams.priceOracle.baseTokens(address(setup.vault)) ==
//                     deployParams.weth
//             );

//             require(
//                 deployParams
//                     .priceOracle
//                     .aggregatorsData(address(setup.vault), deployParams.weth)
//                     .aggregatorV3 == address(deployParams.wethAggregatorV3)
//             );
//             require(
//                 deployParams
//                     .priceOracle
//                     .aggregatorsData(address(setup.vault), deployParams.weth)
//                     .maxAge == 0
//             );
//             require(
//                 deployParams
//                     .priceOracle
//                     .aggregatorsData(address(setup.vault), deployParams.wsteth)
//                     .aggregatorV3 == address(deployParams.wstethAggregatorV3)
//             );
//             require(
//                 deployParams
//                     .priceOracle
//                     .aggregatorsData(address(setup.vault), deployParams.wsteth)
//                     .maxAge == 0
//             );

//             require(
//                 deployParams.priceOracle.priceX96(
//                     address(setup.vault),
//                     deployParams.weth
//                 ) == DeployConstants.Q96
//             );

//             require(
//                 deployParams.priceOracle.priceX96(
//                     address(setup.vault),
//                     deployParams.wsteth
//                 ) ==
//                     (IWSteth(deployParams.wsteth).getStETHByWstETH(1 ether) *
//                         DeployConstants.Q96) /
//                         1 ether
//             );
//         }

//         // DepositWrapper values
//         {
//             require(
//                 address(setup.depositWrapper.vault()) == address(setup.vault),
//                 "Invalid vault"
//             );
//             require(
//                 setup.depositWrapper.weth() == deployParams.weth,
//                 "Invalid weth"
//             );
//             require(
//                 setup.depositWrapper.wsteth() == deployParams.wsteth,
//                 "Invalid wsteth"
//             );
//             require(
//                 setup.depositWrapper.steth() == deployParams.steth,
//                 "Invalid steth"
//             );
//         }

//         // DefaultAccessControl admins
//         {
//             require(
//                 setup.vault.getRoleAdmin(setup.vault.ADMIN_ROLE()) ==
//                     setup.vault.ADMIN_ROLE()
//             );
//             require(
//                 setup.vault.getRoleAdmin(setup.vault.ADMIN_DELEGATE_ROLE()) ==
//                     setup.vault.ADMIN_ROLE()
//             );
//             require(
//                 setup.vault.getRoleAdmin(setup.vault.OPERATOR()) ==
//                     setup.vault.ADMIN_DELEGATE_ROLE()
//             );
//         }
//     }

//     function testValidator() external pure {}
// }
