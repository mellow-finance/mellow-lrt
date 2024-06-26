// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../../scripts/mainnet/Validator.sol";
import "../../../../scripts/mainnet/DeployScript.sol";
import "../../../../scripts/mainnet/DeployConstants.sol";

import "../../Constants.sol";

contract Used is Validator, DeployScript, Test {
    DeployInterfaces.DeployParameters params;
    DeployInterfaces.DeploySetup setup;

    function setUp() external {
        params.deployer = DeployConstants.MAINNET_DEPLOYER;
        params.proxyAdmin = DeployConstants.MELLOW_LIDO_PROXY_MULTISIG;
        params.admin = DeployConstants.MELLOW_LIDO_MULTISIG;
        params.wstethDefaultBond = address(
            new DefaultBondMock(DeployConstants.WSTETH)
        );
        params.wsteth = DeployConstants.WSTETH;
        params.steth = DeployConstants.STETH;
        params.weth = DeployConstants.WETH;
        params.curator = DeployConstants.STEAKHOUSE_MULTISIG;
        params.lpTokenName = DeployConstants.MELLOW_VAULT_NAME;
        params.lpTokenSymbol = DeployConstants.MELLOW_VAULT_SYMBOL;
        params.initialDepositETH = DeployConstants.INITIAL_DEPOSIT_ETH;
        params.maximalTotalSupply = DeployConstants.MAXIMAL_TOTAL_SUPPLY;
        params.firstDepositETH = DeployConstants.FIRST_DEPOSIT_ETH;
        deal(
            params.deployer,
            params.initialDepositETH + params.firstDepositETH
        );
        vm.startPrank(params.deployer);
        params = commonContractsDeploy(params);
        (params, setup) = deploy(params);
        vm.stopPrank();
    }

    function testProcessConfigurators() external {
        RestrictingKeeper keeper = new RestrictingKeeper();

        vm.startPrank(params.admin);
        setup.vault.grantRole(
            setup.vault.ADMIN_DELEGATE_ROLE(),
            address(keeper)
        );
        vm.stopPrank();

        VaultConfigurator[] memory configurators = new VaultConfigurator[](1);
        configurators[0] = VaultConfigurator(address(setup.configurator));
        keeper.processConfigurators(configurators);
    }

    function testProcessConfiguratorsFailsWithForbidden() external {
        RestrictingKeeper keeper = new RestrictingKeeper();

        VaultConfigurator[] memory configurators = new VaultConfigurator[](1);
        configurators[0] = VaultConfigurator(address(setup.configurator));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        keeper.processConfigurators(configurators);
    }
}
