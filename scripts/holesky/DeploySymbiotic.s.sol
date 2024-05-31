// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";

contract Deploy is DeployScript {
    using SafeERC20 for IERC20;

    function run() external {
        validateChainId();
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("HOLESKY_VAULT_ADMIN_PK")))
        );

        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.HOLESKY_DEPLOYER,
                admin: DeployConstants.HOLESKY_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.HOLESKY_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.HOLESKY_CURATOR_MANAGER,
                proposer: DeployConstants.HOLESKY_MELLOW_MULTISIG,
                acceptor: DeployConstants.HOLESKY_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.HOLESKY_MELLOW_MULTISIG,
                wstethDefaultBond: DeployConstants.WSTETH_DEFAULT_BOND,
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.HOLESKY_VAULT_NAME,
                lpTokenSymbol: DeployConstants.HOLESKY_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory s = deploy(deployParams);

        s.vault.calculateStack();

        vm.stopBroadcast();
    }
}
