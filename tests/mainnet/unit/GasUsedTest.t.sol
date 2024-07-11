// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet/Validator.sol";
import "../../../scripts/mainnet/DeployScript.sol";
import "../../../scripts/mainnet/DeployConstants.sol";

import "../Constants.sol";

contract GasUsedTest is Validator, DeployScript, Test {
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

    function testDefaultBondStrategyWithdrawGasUsed() external {
        // clear all pending withdrawals
        vm.prank(params.curator);
        setup.defaultBondStrategy.processAll();
        vm.stopPrank();

        // deposit + withdrawals
        for (uint160 i = 0; i < 18; i++) {
            address depositor = address(
                0x111111111111111111111111111111 * (i + 1)
            );
            deal(depositor, 1 ether);
            vm.startPrank(depositor);
            uint256 lpAmount = setup.depositWrapper.deposit{value: 1 ether}(
                depositor,
                address(0),
                1 ether,
                0,
                type(uint256).max,
                0
            );
            setup.vault.registerWithdrawal(
                depositor,
                lpAmount,
                new uint256[](1),
                type(uint256).max,
                type(uint256).max,
                false
            );
            vm.stopPrank();
        }
        // process
        vm.prank(params.curator);
        uint256 gas = gasleft();
        setup.defaultBondStrategy.processAll();
        console2.log(
            "testDefaultBondStrategyWithdrawGasUsed ",
            gas - gasleft()
        );
        vm.stopPrank();
    }

    function testVaultWithdrawGasUsed() external {
        // clear all pending withdrawals
        vm.prank(params.curator);
        setup.defaultBondStrategy.processAll();
        vm.stopPrank();

        // deposit + withdrawals
        uint256 count = 100;
        address[] memory users = new address[](count);
        for (uint160 i = 0; i < count; i++) {
            address depositor = address(
                0x111111111111111111111111111111 * (i + 1)
            );
            users[i] = depositor;
            deal(depositor, 1 ether);
            vm.startPrank(depositor);
            uint256 lpAmount = setup.depositWrapper.deposit{value: 1 ether}(
                depositor,
                address(0),
                1 ether,
                0,
                type(uint256).max,
                0
            );
            setup.vault.registerWithdrawal(
                depositor,
                lpAmount,
                new uint256[](1),
                type(uint256).max,
                type(uint256).max,
                false
            );
            vm.stopPrank();
        }
        // process
        vm.prank(params.admin);
        uint256 gas = gasleft();
        setup.vault.processWithdrawals(users);
        console2.log("testVaultWithdrawGasUsed ", gas - gasleft());
        vm.stopPrank();
    }
}
