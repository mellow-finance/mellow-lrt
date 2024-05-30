// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";

contract Deploy is DeployScript {
    function run() external {
        vm.startBroadcast(uint256(bytes32(vm.envBytes("MAINNET_DEPLOYER_PK"))));

        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                admin: DeployConstants.STEAKHOUSE_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.STEAKHOUSE_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.STEAKHOUSE_CURATOR_MANAGER,
                proposer: DeployConstants.STEAKHOUSE_MELLOW_MULTISIG,
                acceptor: DeployConstants.STEAKHOUSE_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.STEAKHOUSE_MELLOW_MULTISIG,
                wstethDefaultBond: DeployConstants.WSTETH_DEFAULT_BOND, // to be deployed
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.STEAKHOUSE_VAULT_NAME,
                lpTokenSymbol: DeployConstants.STEAKHOUSE_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });

        DeployLibrary.DeploySetup memory s = deploy(deployParams);
        vm.stopBroadcast();
    }
}
