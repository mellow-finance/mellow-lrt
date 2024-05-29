// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";

library DeployLibrary {
    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE = 2;
    uint8 public constant ADMIN_ROLE = 255;

    struct DeployParameters {
        address deployer;
        address vaultAdmin;
        address vaultCurator;
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
}
