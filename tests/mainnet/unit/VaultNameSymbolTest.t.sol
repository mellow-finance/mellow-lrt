// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";
import "../e2e/DeployScript.sol";

contract VaultNameAndSymbloTestUnit is DeployScript {
    address public immutable deployer = vm.createWallet("deployer").addr;
    address public immutable acceptor = vm.createWallet("acceptor").addr;
    address public immutable proposer = vm.createWallet("proposer").addr;
    address public immutable emergencyOperator =
        vm.createWallet("emergencyOperator").addr;
    address public immutable wsteth =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public immutable weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public immutable vaultAdmin = vm.createWallet("vaultAdmin").addr;
    address public immutable vaultCurator =
        vm.createWallet("vaultCurator").addr;
    address public immutable wstethDefaultBond =
        address(new DefaultBondMock(wsteth));

    function testCheckName() external {
        string memory lpTokenName = "0123456789012345678901234567890";
        string memory lpTokenSymbol = "symbol";
        deal(deployer, 1 gwei);
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: deployer,
                admin: vaultAdmin,
                curator: vaultCurator,
                operator: vaultCurator,
                proposer: proposer,
                acceptor: acceptor,
                emergencyOperator: emergencyOperator,
                wstethDefaultBond: wstethDefaultBond, // deploy
                wsteth: wsteth,
                steth: steth,
                weth: weth,
                maximalTotalSupply: 10_000 ether,
                lpTokenName: lpTokenName, // 31 symbol
                lpTokenSymbol: lpTokenSymbol,
                initialDepositETH: 1 gwei
            });

        DeployLibrary.DeploySetup memory setup = deploy(deployParams);

        assertEq(lpTokenName, setup.vault.name());
    }

    function testCheckSymbol() external {
        string memory lpTokenName = "name";
        string memory lpTokenSymbol = "0123456789012345678901234567890";
        deal(deployer, 1 gwei);
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: deployer,
                admin: vaultAdmin,
                curator: vaultCurator,
                operator: vaultCurator,
                proposer: proposer,
                acceptor: acceptor,
                emergencyOperator: emergencyOperator,
                wstethDefaultBond: wstethDefaultBond, // deploy
                wsteth: wsteth,
                steth: steth,
                weth: weth,
                maximalTotalSupply: 10_000 ether,
                lpTokenName: lpTokenName, // 31 symbol
                lpTokenSymbol: lpTokenSymbol,
                initialDepositETH: 1 gwei
            });

        DeployLibrary.DeploySetup memory setup = deploy(deployParams);

        assertEq(lpTokenSymbol, setup.vault.symbol());
    }
}
