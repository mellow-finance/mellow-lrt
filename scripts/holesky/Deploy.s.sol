// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./Constants.sol";

contract Deploy is Script {
    using SafeERC20 for IERC20;

    function setUpVault(Vault vault) private {
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        vault.addTvlModule(address(erc20TvlModule));

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );

        // oracles setup
        {
            ManagedRatiosOracle ratiosOracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[0] = 0;
            ratiosX96[1] = 2 ** 96; // WETH deposit
            ratiosOracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[1] = 0;
            ratiosX96[0] = 2 ** 96; // WSTETH withdrawal
            ratiosOracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(ratiosOracle));
            configurator.commitRatiosOracle();

            ChainlinkOracle chainlinkOracle = new ChainlinkOracle();
            chainlinkOracle.setBaseToken(address(vault), Constants.WSTETH);
            address[] memory tokens = new address[](2);
            tokens[0] = Constants.WSTETH;
            tokens[1] = Constants.WETH;

            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](2);
            data[0] = IChainlinkOracle.AggregatorData({
                aggregatorV3: address(
                    new WStethRatiosAggregatorV3(Constants.WSTETH)
                ),
                maxAge: 30 days
            });
            data[1] = IChainlinkOracle.AggregatorData({
                aggregatorV3: address(new ConstantAggregatorV3(1 ether)),
                maxAge: 30 days
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

        // creating default bond factory and default bond contract
        address wstethBondContract;
        {
            DefaultCollateralFactory defaultCollateralFactory = new DefaultCollateralFactory();
            wstethBondContract = defaultCollateralFactory.create(
                Constants.WSTETH,
                10_000 ether,
                Constants.VAULT_ADMIN
            );
        }

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );

        DefaultBondModule bondModule = new DefaultBondModule();

        // validators setup
        {
            ManagedValidator validator = new ManagedValidator(
                Constants.VAULT_ADMIN
            );
            DefaultBondValidator bondValidator = new DefaultBondValidator(
                Constants.VAULT_ADMIN
            );
            bondValidator.setSupportedBond(wstethBondContract, true);
            validator.setCustomValidator(
                address(bondModule),
                address(bondValidator)
            );
            configurator.stageValidator(address(validator));
            configurator.commitValidator();
        }

        DefaultBondStrategy bondStrategy = new DefaultBondStrategy(
            Constants.VAULT_ADMIN,
            vault,
            erc20TvlModule,
            bondModule
        );

        SimpleDVTStakingStrategy dvtStrategy = new SimpleDVTStakingStrategy(
            Constants.VAULT_ADMIN,
            vault,
            stakingModule
        );

        vault.grantRole(vault.OPERATOR(), address(bondStrategy));
        vault.grantRole(vault.OPERATOR(), address(dvtStrategy));
    }

    function initialDeposit(Vault vault) public {
        IWeth(Constants.WETH).deposit{value: 10 gwei}();
        IERC20(Constants.WETH).safeIncreaseAllowance(address(vault), 10 gwei);
        uint256[] memory amounts = new uint256[](2);
        amounts[1] = 10 gwei;
        vault.deposit(address(vault), amounts, 10 gwei, type(uint256).max);
    }

    function deployVault() public {
        Vault vault = new Vault(
            "TestTokenName",
            "TestTokenSymbol",
            Constants.VAULT_ADMIN
        );
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        vault.grantRole(vault.OPERATOR(), Constants.VAULT_ADMIN);
        setUpVault(vault);
        initialDeposit(vault);
    }

    function run() external {
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("HOLESKY_VAULT_ADMIN_PK")))
        );

        deployVault();

        vm.stopBroadcast();
    }
}
