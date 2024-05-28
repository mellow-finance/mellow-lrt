// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";

contract VaultTestCommon is Test {
    using SafeERC20 for IERC20;

    address public immutable admin =
        address(bytes20(keccak256("mellow-vault-admin")));

    address public immutable operator =
        address(bytes20(keccak256("mellow-vault-operator")));

    function _setUp(Vault vault) internal {
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        vault.addTvlModule(address(erc20TvlModule));

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.RETH);
        vault.addToken(Constants.WETH);
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );

        // oracles setup
        {
            ManagedRatiosOracle ratiosOracle = new ManagedRatiosOracle();

            uint128[] memory ratiosX96 = new uint128[](3);
            ratiosX96[0] = 2 ** 96;
            ratiosOracle.updateRatios(address(vault), true, ratiosX96);
            ratiosOracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(ratiosOracle));
            configurator.commitRatiosOracle();

            ChainlinkOracle chainlinkOracle = new ChainlinkOracle();
            chainlinkOracle.setBaseToken(address(vault), Constants.WSTETH);
            address[] memory tokens = new address[](3);
            tokens[0] = Constants.WSTETH;
            tokens[1] = Constants.RETH;
            tokens[2] = Constants.WETH;

            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](3);
            data[0] = IChainlinkOracle.AggregatorData({
                aggregatorV3: address(
                    new WStethRatiosAggregatorV3(Constants.WSTETH)
                ),
                maxAge: 30 days
            });
            data[1] = IChainlinkOracle.AggregatorData({
                aggregatorV3: Constants.RETH_CHAINLINK_ORACLE,
                maxAge: 30 days
            });
            data[2] = IChainlinkOracle.AggregatorData({
                aggregatorV3: address(new ConstantAggregatorV3(1 ether)),
                maxAge: 30 days
            });
            chainlinkOracle.setChainlinkOracles(address(vault), tokens, data);

            configurator.stagePriceOracle(address(chainlinkOracle));
            configurator.commitPriceOracle();
        }

        configurator.stageMaximalTotalSupply(1000 ether);
        configurator.commitMaximalTotalSupply();
    }

    function _initialDeposit(Vault vault) internal {
        vm.startPrank(admin);
        _setupDepositPermissions(vault);
        vm.stopPrank();

        vm.startPrank(operator);
        deal(Constants.WSTETH, operator, 10 gwei);
        deal(Constants.RETH, operator, 0 ether);
        deal(Constants.WETH, operator, 0 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), 10 gwei);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 gwei;
        vault.deposit(address(vault), amounts, 10 gwei, type(uint256).max);

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 10 gwei);
        assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);
        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(operator), 0);

        vm.stopPrank();
    }

    function _setupDepositPermissions(IVault vault) internal {
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        uint8 depositRole = 14;
        IManagedValidator validator = IManagedValidator(
            configurator.validator()
        );
        if (address(validator) == address(0)) {
            validator = new ManagedValidator(admin);
            configurator.stageValidator(address(validator));
            configurator.commitValidator();
        }
        validator.grantPublicRole(depositRole);
        validator.grantContractSignatureRole(
            address(vault),
            IVault.deposit.selector,
            depositRole
        );
    }
}
