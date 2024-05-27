// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./Constants.sol";

contract Deploy is Script {
    using SafeERC20 for IERC20;

    Vault public vault;
    VaultConfigurator public configurator;

    ERC20TvlModule public erc20TvlModule;
    DefaultBondTvlModule public defaultBondTvlModule;

    DefaultBondModule public bondModule;

    ManagedValidator public validator;
    DefaultBondValidator public bondValidator;

    ManagedRatiosOracle public ratiosOracle;

    ChainlinkOracle public chainlinkOracle;

    DefaultBondStrategy public bondStrategy;

    address public wstethDefaultBond;

    DepositWrapper public depositWrapper;

    Collector public collector;

    function setUpVault() private {
        erc20TvlModule = new ERC20TvlModule();
        defaultBondTvlModule = new DefaultBondTvlModule();

        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(defaultBondTvlModule));

        vault.addToken(Constants.WSTETH);

        configurator = VaultConfigurator(address(vault.configurator()));
        // oracles setup
        {
            ratiosOracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](1);
            ratiosX96[0] = 2 ** 96; // WSTETH deposit
            ratiosOracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[0] = 2 ** 96; // WSTETH withdrawal
            ratiosOracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(ratiosOracle));
            configurator.commitRatiosOracle();

            chainlinkOracle = new ChainlinkOracle();
            chainlinkOracle.setBaseToken(address(vault), Constants.WSTETH);
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
            DefaultCollateralFactory defaultCollateralFactory = DefaultCollateralFactory(
                    Constants.DEFAULT_COLLATERAL_FACTORY
                );
            wstethDefaultBond = defaultCollateralFactory.create(
                Constants.WSTETH,
                10_000 ether,
                Constants.VAULT_ADMIN
            );
            address[] memory supportedBonds = new address[](1);
            supportedBonds[0] = wstethDefaultBond;
            defaultBondTvlModule.setParams(address(vault), supportedBonds);
        }

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
            configurator.stageDepositCallback(address(bondStrategy));
            configurator.commitDepositCallback();
        }

        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0].bond = wstethDefaultBond;
            data[0].ratioX96 = Constants.Q96;
            bondStrategy.setData(Constants.WSTETH, data);
        }

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

        depositWrapper = new DepositWrapper(
            vault,
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );
    }

    function initialDeposit() public {
        ISteth(Constants.STETH).submit{value: 10 gwei}(address(0));
        IERC20(Constants.STETH).safeIncreaseAllowance(
            Constants.WSTETH,
            10 gwei
        );
        IWSteth(Constants.WSTETH).wrap(10 gwei);
        uint256 amount = IERC20(Constants.WSTETH).balanceOf(
            Constants.VAULT_ADMIN
        );
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), amount);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        vault.deposit(address(vault), amounts, amount, type(uint256).max);
    }

    function regularDeposit(uint256 amount) public {
        depositWrapper.deposit{value: amount}(
            Constants.VAULT_ADMIN,
            address(0), // eth
            amount,
            (amount * 80) / 100,
            type(uint256).max
        );
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
        regularDeposit(10000 gwei);
    }

    function print() public view {
        console2.log("Vault: %s", address(vault));
        console2.log("VaultConfigurator: %s", address(configurator));
        console2.log("ERC20TvlModule: %s", address(erc20TvlModule));
        console2.log("DefaultBondTvlModule: %s", address(defaultBondTvlModule));
        console2.log("DefaultBondModule: %s", address(bondModule));
        console2.log("ManagedValidator: %s", address(validator));
        console2.log("DefaultBondValidator: %s", address(bondValidator));
        console2.log("ManagedRatiosOracle: %s", address(ratiosOracle));
        console2.log("ChainlinkOracle: %s", address(chainlinkOracle));
        console2.log("DefaultBondStrategy: %s", address(bondStrategy));
        console2.log("WStethDefaultBond: %s", address(wstethDefaultBond));
        console2.log("DepositWrapper: %s", address(depositWrapper));
        // console2.log("Collector: %s", address(collector));
    }

    function run() external {
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("HOLESKY_VAULT_ADMIN_PK")))
        );

        IAggregatorV3 wstethChainlinkAggregator = new WStethRatiosAggregatorV3(
            Constants.WSTETH
        );
        IAggregatorV3 wethToUSDChainlinkAggregator = new ConstantAggregatorV3(
            3800 * 1e8
        );
        collector = new Collector(
            Constants.WSTETH,
            wstethChainlinkAggregator,
            wethToUSDChainlinkAggregator
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 989508703726688500;
        collector.fetchDepositAmounts(
            amounts,
            0xEBB01cfBc08A891ca81034B80DBE7748963AdE53,
            0xf2d8A1fc85DbaE3A24196ed27F021B2c4E439a7F
        );

        // address a = 0xf2d8A1fc85DbaE3A24196ed27F021B2c4E439a7F;

        // IWeth(Constants.WETH).deposit{value: 1 ether}();
        // ISteth(Constants.STETH).submit{value: 2 ether}(address(0));
        // IERC20(Constants.STETH).safeIncreaseAllowance(
        //     Constants.WSTETH,
        //     1 ether
        // );
        // IWSteth(Constants.WSTETH).wrap(1 ether);
        // payable(a).transfer(1 ether);
        // IERC20(Constants.WETH).safeTransfer(a, 1 ether);
        // IERC20(Constants.STETH).safeTransfer(a, 1 ether);
        // IERC20(Constants.WSTETH).safeTransfer(a, IERC20(Constants.WSTETH).balanceOf(Constants.VAULT_ADMIN));

        // deployVault();
        // deployCollector();
        vm.stopBroadcast();
        print();
        // preventing accidental deployment
        revert("Failed successfully");
    }
}
