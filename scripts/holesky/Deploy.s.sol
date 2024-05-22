// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

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
                aggregatorV3: address(new ConstantAggregatorV3(10 ** 18)),
                maxAge: 30 days
            });

            chainlinkOracle.setChainlinkOracles(address(vault), tokens, data);
            configurator.stagePriceOracle(address(chainlinkOracle));
            configurator.commitPriceOracle();
        }

        // setting initial total supply
        configurator.stageMaximalTotalSupply(10_000 ether);
        configurator.commitMaximalTotalSupply();
    }

    function initialDeposit(Vault vault) public {
        IWeth(Constants.WETH).deposit{value: 10 gwei}();
        IERC20(Constants.WETH).safeIncreaseAllowance(address(vault), 10 gwei);
        uint256[] memory amounts = new uint256[](2);
        amounts[1] = 10 gwei;
        vault.deposit(address(vault), amounts, 10 gwei, type(uint256).max);
    }

    function deployVault() public {
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("HOLESKY_VAULT_ADMIN_PK")))
        );
        Vault vault = new Vault(
            "TestTokenName",
            "TestTokenSymbol",
            Constants.VAULT_ADMIN
        );
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        vault.grantRole(vault.OPERATOR(), Constants.VAULT_OPERATOR);
        setUpVault(vault);
        initialDeposit(vault);

        vm.stopBroadcast();
    }

    function run() external {
        deployVault();
    }
}
