// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";
import "../../e2e/DeployLibrary.sol";
import "../../e2e/DeployScript.sol";

contract RestrictingKeeperTestUnit is Test, DeployScript {
    address public immutable admin = vm.createWallet("admin").addr;
    address public immutable user = vm.createWallet("user").addr;
    address public immutable deployer = vm.createWallet("deployer").addr;
    address public immutable acceptor = vm.createWallet("acceptor").addr;
    address public immutable proposer = vm.createWallet("proposer").addr;
    address public immutable emergencyOperator =
        vm.createWallet("emergencyOperator").addr;
    address public immutable wsteth =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public immutable weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public immutable vaultCurator =
        vm.createWallet("vaultCurator").addr;
    address public immutable wstethDefaultBond =
        address(new DefaultBondMock(wsteth));

    function testConstructorSuccess() external {
        RestrictingKeeper keeper = new RestrictingKeeper(admin);
        assertNotEq(address(keeper), address(0));
    }

    function testProcessConfiguratorsEmptyArraySuccess() external {
        RestrictingKeeper keeper = new RestrictingKeeper(admin);

        vm.startPrank(admin);

        VaultConfigurator[] memory configurators;
        keeper.processConfigurators(configurators);
        vm.stopPrank();
    }

    function testProcessConfiguratorsEmptyMemberFail() external {
        RestrictingKeeper keeper = new RestrictingKeeper(admin);

        vm.startPrank(admin);

        VaultConfigurator[] memory configurators = new VaultConfigurator[](1);

        configurators[0] = new VaultConfigurator();

        vm.expectRevert();
        keeper.processConfigurators(configurators);

        vm.stopPrank();
    }

    function testProcessConfiguratorsNotAdminFail() external {
        RestrictingKeeper keeper = new RestrictingKeeper(admin);

        vm.startPrank(user);

        VaultConfigurator[] memory configurators;

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        keeper.processConfigurators(configurators);

        vm.stopPrank();
    }

    function testProcessConfiguratorsSuccess() external {
        RestrictingKeeper keeper = new RestrictingKeeper(admin);

        deal(deployer, 1 gwei);
        DeployLibrary.DeployParameters memory deployParams = DeployLibrary
            .DeployParameters({
                deployer: deployer,
                admin: address(keeper),
                curator: vaultCurator,
                operator: vaultCurator,
                proposer: proposer,
                acceptor: acceptor,
                emergencyOperator: emergencyOperator,
                wstethDefaultBond: wstethDefaultBond,
                wsteth: wsteth,
                steth: steth,
                weth: weth,
                maximalTotalSupply: 10_000 ether,
                lpTokenName: "name",
                lpTokenSymbol: "symbol",
                initialDepositETH: 1 gwei
            });

        DeployLibrary.DeploySetup memory setup = deploy(deployParams);

        VaultConfigurator[] memory configurators = new VaultConfigurator[](1);

        VaultConfigurator configurator = VaultConfigurator(
            address(setup.configurator)
        );
        configurators[0] = configurator;

        vm.startPrank(admin);

        keeper.processConfigurators(configurators);

        vm.stopPrank();
    }
}
