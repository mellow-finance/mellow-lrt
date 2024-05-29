// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";

interface IDeploy {
    struct DeployParameters {
        address deployer;
        address vaultAdmin;
        address vaultCurator;
        address proposer;
        address acceptor;
        address emergencyOperator;
        address baseImplementation;
        address wstethDefaultBond;
        uint256 maximalTotalSupply;
        string lpTokenName;
        string lpTokenSymbol;
    }

    struct DeploySetup {
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
    }
}
