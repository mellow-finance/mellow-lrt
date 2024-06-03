// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./Imports.sol";
import "./DeployScript.sol";
import "./DeployLibrary.sol";
import "./ValidationLibrary.sol";

contract Deploy is Script, DeployScript {
    function run() external {
        DeployLibrary.DeployParameters memory deployParams;

        bool test = true;
        uint256 n = 4;

        address[] memory curators = new address[](n);
        curators[0] = DeployConstants.STEAKHOUSE_MULTISIG;
        curators[1] = DeployConstants.RE7_MULTISIG;
        curators[2] = DeployConstants.MEV_MULTISIG;
        curators[3] = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        string[] memory names = new string[](n);
        names[0] = DeployConstants.STEAKHOUSE_VAULT_TEST_NAME;
        names[1] = DeployConstants.RE7_VAULT_TEST_NAME;
        names[2] = DeployConstants.MEV_VAULT_TEST_NAME;
        names[3] = DeployConstants.MELLOW_VAULT_NAME;

        string[] memory symbols = new string[](n);
        symbols[0] = DeployConstants.STEAKHOUSE_VAULT_TEST_SYMBOL;
        symbols[1] = DeployConstants.RE7_VAULT_TEST_SYMBOL;
        symbols[2] = DeployConstants.MEV_VAULT_TEST_SYMBOL;
        symbols[3] = DeployConstants.MELLOW_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_TEST_DEPLOYER;
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("MAINNET_TEST_DEPLOYER")))
        );

        deployParams.proxyAdmin = DeployConstants
            .MELLOW_LIDO_TEST_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        // only for testing purposes
        if (test) {
            TransparentUpgradeableProxy factory = new TransparentUpgradeableProxy(
                    DeployConstants.WSTETH_DEFAULT_BOND_FACTORY,
                    address(0),
                    ""
                );

            deployParams.wstethDefaultBond = IDefaultCollateralFactory(
                address(factory)
            ).create(DeployConstants.WSTETH, type(uint256).max, address(0));
        } else {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
        }
        deployParams.wstethDefaultBondFactory = DeployConstants
            .WSTETH_DEFAULT_BOND_FACTORY;

        deployParams.wsteth = DeployConstants.WSTETH;
        deployParams.steth = DeployConstants.STETH;
        deployParams.weth = DeployConstants.WETH;

        deployParams.maximalTotalSupply = DeployConstants.MAXIMAL_TOTAL_SUPPLY;
        deployParams.initialDepositETH = DeployConstants.INITIAL_DEPOSIT_ETH;
        deployParams.timeLockDelay = DeployConstants.TIMELOCK_TEST_DELAY;

        for (uint256 i = 0; i < n; i++) {
            deployParams.curator = curators[i];
            deployParams.lpTokenName = names[i];
            deployParams.lpTokenSymbol = symbols[i];
            DeployLibrary.DeploySetup memory setup;
            (deployParams, setup) = deploy(deployParams);
            ValidationLibrary.validateParameters(deployParams, setup);
        }

        vm.stopBroadcast();
    }
}
