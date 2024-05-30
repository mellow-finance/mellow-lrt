// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Imports.sol";
import "./DeployConstants.sol";

library DeployLibrary {
    struct DeployParameters {
        address deployer;
        address admin;
        address curator;
        address operator;
        address proposer;
        address acceptor;
        address emergencyOperator;
        address wstethDefaultBond;
        address wsteth;
        address steth;
        address weth;
        uint256 maximalTotalSupply;
        string lpTokenName;
        string lpTokenSymbol;
        uint256 initialDepositETH;
    }

    struct DeploySetup {
        Initializer initializer;
        Vault vault;
        Vault initialImplementation;
        IVaultConfigurator configurator;
        ERC20TvlModule erc20TvlModule;
        DefaultBondTvlModule defaultBondTvlModule;
        DefaultBondModule defaultBondModule;
        ManagedValidator validator;
        ManagedRatiosOracle ratiosOracle;
        ChainlinkOracle priceOracle;
        DefaultBondStrategy defaultBondStrategy;
        DepositWrapper depositWrapper;
        DefaultProxyImplementation defaultProxyImplementation;
        AdminProxy adminProxy;
        RestrictingKeeper restrictingKeeper;
        IAggregatorV3 wethAggregatorV3;
        IAggregatorV3 wstethAggregatorV3;
        uint256 wstethAmountDeposited;
    }

    function test() external pure {}
}
