// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./Constants.sol";

contract Deploy is Script {
    using SafeERC20 for IERC20;

    Vault public vault;
    VaultConfigurator public configurator;

    ERC20TvlModule public erc20TvlModule;
    DefaultBondTvlModule public defaultBondTvlModule;

    StakingModule public stakingModule;
    DefaultBondModule public bondModule;

    ManagedValidator public validator;
    DefaultBondValidator public bondValidator;

    ManagedRatiosOracle public ratiosOracle;

    ChainlinkOracle public chainlinkOracle;
    ConstantAggregatorV3 public wethToETHChainlinkAggregator;
    ConstantAggregatorV3 public wethToUSDChainlinkAggregator;
    WStethRatiosAggregatorV3 public wstethChainlinkAggregator;

    DefaultBondStrategy public bondStrategy;
    SimpleDVTStakingStrategy public dvtStrategy;

    DefaultCollateralFactory public defaultCollateralFactory;
    address public wstethDefaultBond;

    Collector public collector;

    function setUpVault() private {
        erc20TvlModule = new ERC20TvlModule();
        defaultBondTvlModule = new DefaultBondTvlModule();

        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(defaultBondTvlModule));

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);

        configurator = VaultConfigurator(address(vault.configurator()));
        // oracles setup
        {
            ratiosOracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[0] = 0;
            ratiosX96[1] = 2 ** 96; // WETH deposit
            ratiosOracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[1] = 0;
            ratiosX96[0] = 2 ** 96; // WSTETH withdrawal
            ratiosOracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(ratiosOracle));
            configurator.commitRatiosOracle();

            chainlinkOracle = new ChainlinkOracle();
            chainlinkOracle.setBaseToken(address(vault), Constants.WSTETH);
            address[] memory tokens = new address[](2);
            tokens[0] = Constants.WSTETH;
            tokens[1] = Constants.WETH;

            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](2);

            wstethChainlinkAggregator = new WStethRatiosAggregatorV3(
                Constants.WSTETH
            );
            wethToETHChainlinkAggregator = new ConstantAggregatorV3(1 ether);
            wethToUSDChainlinkAggregator = new ConstantAggregatorV3(3800 * 1e8);

            data[0] = IChainlinkOracle.AggregatorData({
                aggregatorV3: address(wstethChainlinkAggregator),
                maxAge: 0 // due to the fact that we are using instant aggregator implementation
            });
            data[1] = IChainlinkOracle.AggregatorData({
                aggregatorV3: address(wethToETHChainlinkAggregator),
                maxAge: 0 // due to the fact that we are using instant aggregator implementation
            });

            chainlinkOracle.setChainlinkOracles(address(vault), tokens, data);
            configurator.stagePriceOracle(address(chainlinkOracle));
            configurator.commitPriceOracle();
        }

        // setting initial total supply
        {
            configurator.stageMaximalTotalSupply(10_000 ether);
            configurator.commitMaximalTotalSupply();
        }

        // creating default bond factory and default bond contract for wsteth
        {
            // symbiotic contracts
            defaultCollateralFactory = new DefaultCollateralFactory();
            wstethDefaultBond = defaultCollateralFactory.create(
                Constants.WSTETH,
                10_000 ether,
                Constants.VAULT_ADMIN
            );
            address[] memory supportedBonds = new address[](1);
            supportedBonds[0] = wstethDefaultBond;
            defaultBondTvlModule.setParams(address(vault), supportedBonds);
        }

        stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        configurator.stageDelegateModuleApproval(address(stakingModule));
        configurator.commitDelegateModuleApproval(address(stakingModule));

        bondModule = new DefaultBondModule();

        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        bondStrategy = new DefaultBondStrategy(
            Constants.VAULT_ADMIN,
            vault,
            erc20TvlModule,
            bondModule
        );
        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0].bond = wstethDefaultBond;
            data[0].ratioX96 = Constants.Q96;
            bondStrategy.setData(Constants.WSTETH, data);
        }
        dvtStrategy = new SimpleDVTStakingStrategy(
            Constants.VAULT_ADMIN,
            vault,
            stakingModule
        );

        // validators setup
        validator = new ManagedValidator(Constants.VAULT_ADMIN);
        {
            bondValidator = new DefaultBondValidator(Constants.VAULT_ADMIN);
            bondValidator.setSupportedBond(wstethDefaultBond, true);
            validator.setCustomValidator(
                address(bondModule),
                address(bondValidator)
            );

            validator.grantRole(
                address(bondStrategy),
                Constants.defaultBondStrategyRole
            );
            validator.grantContractRole(
                address(vault),
                Constants.defaultBondStrategyRole
            );

            validator.grantRole(
                address(vault),
                Constants.defaultBondModuleRole
            );
            validator.grantContractRole(
                address(bondModule),
                Constants.defaultBondModuleRole
            );

            validator.grantRole(
                address(dvtStrategy),
                Constants.simpleDvtStrategyRole
            );
            validator.grantContractRole(
                address(vault),
                Constants.simpleDvtStrategyRole
            );

            validator.grantRole(address(vault), Constants.simpleDvtModuleRole);
            validator.grantContractRole(
                address(stakingModule),
                Constants.simpleDvtModuleRole
            );

            validator.grantPublicRole(Constants.depositRole);
            validator.grantContractSignatureRole(
                address(vault),
                IVault.deposit.selector,
                Constants.depositRole
            );

            configurator.stageValidator(address(validator));
            configurator.commitValidator();
        }

        vault.grantRole(vault.OPERATOR(), address(bondStrategy));
        vault.grantRole(vault.OPERATOR(), address(dvtStrategy));
    }

    function initialDeposit() public {
        IWeth(Constants.WETH).deposit{value: 10 gwei}();
        IERC20(Constants.WETH).safeIncreaseAllowance(address(vault), 10 gwei);
        uint256[] memory amounts = new uint256[](2);
        amounts[1] = 10 gwei;
        vault.deposit(address(vault), amounts, 10 gwei, type(uint256).max);
    }

    function regularDeposit(uint256 amount) public {
        IWeth(Constants.WETH).deposit{value: amount}();
        IERC20(Constants.WETH).safeIncreaseAllowance(address(vault), amount);
        uint256[] memory amounts = new uint256[](2);
        amounts[1] = amount;
        vault.deposit(
            address(Constants.VAULT_ADMIN),
            amounts,
            amount,
            type(uint256).max
        );
    }

    function convertAllWethToWSteh(bool enableInitialChecks) public {
        uint256 wethBalance = IERC20(Constants.WETH).balanceOf(address(vault));
        (bool success, ) = vault.delegateCall(
            address(stakingModule),
            abi.encodeWithSelector(stakingModule.convert.selector, wethBalance)
        );

        assert(success);
        if (enableInitialChecks) {
            assert(IERC20(Constants.WETH).balanceOf(address(vault)) == 0);
            assert(IERC20(Constants.WSTETH).balanceOf(address(vault)) != 0);
        }
    }

    function wrapAllIntoSymbioticBond(bool enableInitialChecks) public {
        uint256 wstethVaultBalance = IERC20(Constants.WSTETH).balanceOf(
            address(vault)
        );
        assert(wstethVaultBalance != 0);
        bondStrategy.depositCallback(new uint256[](0), 0);
        uint256 bondVaultBalace = IERC20(wstethDefaultBond).balanceOf(
            address(vault)
        );
        if (enableInitialChecks) {
            assert(wstethVaultBalance == bondVaultBalace);
            wstethVaultBalance = IERC20(Constants.WSTETH).balanceOf(
                address(vault)
            );
            assert(wstethVaultBalance == 0);
            uint256 wstethBondBalance = IERC20(Constants.WSTETH).balanceOf(
                wstethDefaultBond
            );
            assert(wstethBondBalance == bondVaultBalace);
        }
    }

    function regularRegisterWithdrawal() public {
        uint256 lpAmount = vault.balanceOf(Constants.VAULT_ADMIN) >> 1;
        uint256[] memory minAmounts = new uint256[](2);
        minAmounts[0] = lpAmount;
        minAmounts[1] = 0;
        vault.registerWithdrawal(
            Constants.VAULT_ADMIN,
            lpAmount,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );

        (
            bool isProcessingPossible,
            bool isWithdrawalPossible,
            uint256[] memory expectedAmounts
        ) = vault.analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(Constants.VAULT_ADMIN)
            );

        console2.log(
            isProcessingPossible,
            isWithdrawalPossible,
            expectedAmounts[0],
            expectedAmounts[1]
        );
    }

    function deployVault() public {
        vault = new Vault(
            "TestTokenName",
            "TestTokenSymbol",
            Constants.VAULT_ADMIN
        );

        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        vault.grantRole(vault.OPERATOR(), Constants.VAULT_ADMIN);
        setUpVault();
        initialDeposit();
        convertAllWethToWSteh(true);
        wrapAllIntoSymbioticBond(true);
        regularDeposit(10000 gwei);
        convertAllWethToWSteh(false);
        wrapAllIntoSymbioticBond(false);
    }

    function deployCollector() public {
        collector = new Collector(
            Constants.WSTETH,
            wstethChainlinkAggregator,
            wethToUSDChainlinkAggregator
        );
        address[] memory vaults = new address[](1);
        vaults[0] = address(vault);
        Collector.Response memory r = collector.collect(
            Constants.VAULT_ADMIN,
            vaults
        )[0];

        console2.log("Total supply: %d", r.totalSupply);
        console2.log("Total value in ETH: %d", r.totalValueETH);
        console2.log("Total value in USD: %d", r.totalValueUSDC);
        console2.log("Vault address %s", r.vault);
        console2.log("Used lp token balance: %d", r.balance);

        console2.log(
            "Underlying tokens: %s %s",
            IERC20Metadata(r.underlyingTokens[0]).symbol(),
            IERC20Metadata(r.underlyingTokens[1]).symbol()
        );
        console2.log(
            "Underlying amounts: %d",
            r.underlyingAmounts[0],
            r.underlyingAmounts[1]
        );
        console2.log(
            "Underlying token decimals: %d %d",
            r.underlyingTokenDecimals[0],
            r.underlyingTokenDecimals[1]
        );
        console2.log(
            "Deposit ratios X96: %d %d",
            r.depositRatiosX96[0],
            r.depositRatiosX96[1]
        );
        console2.log(
            "Withdrawal ratios X96: %d %d",
            r.withdrawalRatiosX96[0],
            r.withdrawalRatiosX96[1]
        );
        console2.log("Prices X96: %d %d", r.pricesX96[0], r.pricesX96[1]);
        console2.log("User balance ETH: %d", r.userBalanceETH);
        console2.log("User balance USDC: %d", r.userBalanceUSDC);
        console2.log("LP price D18: %d", r.lpPriceD18);
        console2.log(
            "Should close withdrawal request: %s",
            r.shouldCloseWithdrawalRequest
        );
    }

    function print() public view {
        console2.log("Vault: %s", address(vault));
        console2.log("VaultConfigurator: %s", address(configurator));
        console2.log("ERC20TvlModule: %s", address(erc20TvlModule));
        console2.log("DefaultBondTvlModule: %s", address(defaultBondTvlModule));
        console2.log("StakingModule: %s", address(stakingModule));
        console2.log("DefaultBondModule: %s", address(bondModule));
        console2.log("ManagedValidator: %s", address(validator));
        console2.log("DefaultBondValidator: %s", address(bondValidator));
        console2.log("ManagedRatiosOracle: %s", address(ratiosOracle));
        console2.log("ChainlinkOracle: %s", address(chainlinkOracle));
        console2.log(
            "weth-to-eth ConstantAggregatorV3: %s",
            address(wethToETHChainlinkAggregator)
        );
        console2.log(
            "weth-to-usd (testnet mock) ConstantAggregatorV3: %s",
            address(wethToUSDChainlinkAggregator)
        );
        console2.log(
            "WStethRatiosAggregatorV3: %s",
            address(wstethChainlinkAggregator)
        );
        console2.log("DefaultBondStrategy: %s", address(bondStrategy));
        console2.log("SimpleDVTStakingStrategy: %s", address(dvtStrategy));
        console2.log("WStethDefaultBond: %s", address(wstethDefaultBond));
        console2.log(
            "DefaultCollateralFactory: %s",
            address(defaultCollateralFactory)
        );

        console2.log("Collector: %s", address(collector));
    }

    function run() external {
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("HOLESKY_VAULT_ADMIN_PK")))
        );

        deployVault();
        deployCollector();
        vm.stopBroadcast();
        print();
        // preventing accidental deployment
        // revert("Failed successfully");
    }
}
