// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./ValidationLibrary.sol";

import "./DeployConstants.sol";

contract AcceptanceTest is DeployScript {
    address public immutable wstethDefaultBond =
        address(new DefaultBondMock(DeployConstants.WSTETH));

    function testDeployWithValidation() external {
        string memory lpTokenName = "Mellow LRT Token";
        string memory lpTokenSymbol = "MLRT";
        deal(DeployConstants.MAINNET_DEPLOYER, 10 gwei);
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
                maximalTotalSupply: 10_000 ether,
                lpTokenName: lpTokenName,
                lpTokenSymbol: lpTokenSymbol,
                initialDepositETH: 10 gwei
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    }
}
