// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./Imports.sol";
import "./DeployConstants.sol";

library DeployLibrary {
    struct DeployParameters {
        address deployer;
        address proxyAdmin;
        address admin;
        address curator;
        address wstethDefaultBondFactory;
        address wstethDefaultBond;
        address wsteth;
        address steth;
        address weth;
        uint256 maximalTotalSupply;
        string lpTokenName;
        string lpTokenSymbol;
        uint256 initialDepositETH;
        uint256 firstDepositETH;
        uint256 timeLockDelay;
        Initializer initializer;
        ERC20TvlModule erc20TvlModule;
        DefaultBondTvlModule defaultBondTvlModule;
        DefaultBondModule defaultBondModule;
        ManagedRatiosOracle ratiosOracle;
        ChainlinkOracle priceOracle;
        IAggregatorV3 wethAggregatorV3;
        IAggregatorV3 wstethAggregatorV3;
        DefaultProxyImplementation defaultProxyImplementation;
    }

    struct DeploySetup {
        Vault vault; // TransparantUpgradeableProxy
        Vault initialImplementation; // base proxy implementation
        IVaultConfigurator configurator;
        ManagedValidator validator;
        DefaultBondStrategy defaultBondStrategy;
        DepositWrapper depositWrapper;
        TimelockController timeLockedCurator;
        uint256 wstethAmountDeposited;
    }

    function test() external pure {}
}
