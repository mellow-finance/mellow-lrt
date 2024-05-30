// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./ValidationLibrary.sol";

import "./DeployConstants.sol";

contract AcceptanceTest is DeployScript {
    address public immutable wstethDefaultBond =
        address(new DefaultBondMock(DeployConstants.WSTETH));

    function testDeployWithValidationSteakhouseFinancial() external {
        deal(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
        );
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                admin: DeployConstants.STEAKHOUSE_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.STEAKHOUSE_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.STEAKHOUSE_CURATOR_MANAGER,
                proposer: DeployConstants.STEAKHOUSE_MELLOW_MULTISIG,
                acceptor: DeployConstants.STEAKHOUSE_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.STEAKHOUSE_MELLOW_MULTISIG,
                wstethDefaultBond: wstethDefaultBond, // to be deployed
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.STEAKHOUSE_VAULT_NAME,
                lpTokenSymbol: DeployConstants.STEAKHOUSE_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    }

    function testDeployWithValidationRe7Labs() external {
        deal(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
        );
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                admin: DeployConstants.RE7_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.RE7_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.RE7_CURATOR_MANAGER,
                proposer: DeployConstants.RE7_MELLOW_MULTISIG,
                acceptor: DeployConstants.RE7_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.RE7_MELLOW_MULTISIG,
                wstethDefaultBond: wstethDefaultBond, // to be deployed
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.RE7_VAULT_NAME,
                lpTokenSymbol: DeployConstants.RE7_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    }

    function testDeployWithValidationP2P() external {
        deal(
            DeployConstants.MAINNET_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
        );
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                admin: DeployConstants.P2P_CURATOR_BOARD_MULTISIG,
                curator: DeployConstants.P2P_CURATOR_BOARD_MULTISIG,
                operator: DeployConstants.P2P_CURATOR_MANAGER,
                proposer: DeployConstants.P2P_MELLOW_MULTISIG,
                acceptor: DeployConstants.P2P_LIDO_MELLOW_MULTISIG,
                emergencyOperator: DeployConstants.P2P_MELLOW_MULTISIG,
                wstethDefaultBond: wstethDefaultBond, // to be deployed
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                lpTokenName: DeployConstants.P2P_VAULT_NAME,
                lpTokenSymbol: DeployConstants.P2P_VAULT_SYMBOL,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_VALUE
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    }
}
