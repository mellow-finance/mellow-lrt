// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./ValidationLibrary.sol";

contract SimpleDepositWithdrawE2ETest is DeployScript {
    address public immutable deployer = vm.createWallet("deployer").addr;
    address public immutable acceptor = vm.createWallet("acceptor").addr;
    address public immutable proposer = vm.createWallet("proposer").addr;
    address public immutable emergencyOperator =
        vm.createWallet("emergencyOperator").addr;
    address public immutable wsteth = vm.createWallet("wsteth").addr;
    address public immutable weth = vm.createWallet("weth").addr;
    address public immutable steth = vm.createWallet("steth").addr;
    address public immutable vaultAdmin = vm.createWallet("vaultAdmin").addr;
    address public immutable vaultCurator =
        vm.createWallet("vaultCurator").addr;
    address public immutable wstethDefaultBond =
        vm.createWallet("wstethDefaultBond").addr;

    function _testDepsitWithdrawE2E() external {
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: deployer,
                vaultAdmin: vaultAdmin,
                vaultCurator: vaultCurator,
                proposer: proposer,
                acceptor: acceptor,
                emergencyOperator: emergencyOperator,
                wstethDefaultBond: wstethDefaultBond, // deploy
                wsteth: wsteth,
                steth: steth,
                weth: weth,
                maximalTotalSupply: 10_000 ether,
                lpTokenName: "Mellow LRT Vault",
                lpTokenSymbol: "MLRT"
            });
        DeployLibrary.DeploySetup memory setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
    }
}
