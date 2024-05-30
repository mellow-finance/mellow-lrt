// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../ValidationLibrary.sol";
import "../DeployScript.sol";

contract RegularDepositWithdrawalScenario is DeployScript {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct UserState {
        uint256 lpBalance;
        uint256 wstethBalance;
        IVault.WithdrawalRequest withdrawalRequest;
    }

    DeployLibrary.DeploySetup private setup;
    EnumerableSet.AddressSet private allUsers;
    uint256 private epoch = 0;
    mapping(uint256 => mapping(address => UserState)) private usersSystemState;

    function updateSystemState() public {
        uint256 currentEpoch = epoch++;
        for (uint256 i = 0; i < allUsers.length(); i++) {
            address user = allUsers.at(i);
            usersSystemState[currentEpoch][user].wstethBalance = IERC20(
                DeployConstants.WSTETH
            ).balanceOf(user);
            usersSystemState[currentEpoch][user].lpBalance = setup
                .vault
                .balanceOf(user);
            usersSystemState[currentEpoch][user].withdrawalRequest = setup
                .vault
                .withdrawalRequest(user);
        }
    }

    function addUser(string memory label) public returns (address user) {
        user = vm.createWallet(label).addr;
        allUsers.add(user);
    }

    function setUp() external {
        validateChainId();
        deal(
            DeployConstants.HOLESKY_DEPLOYER,
            DeployConstants.INITIAL_DEPOSIT_VALUE
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
        setup = deploy(deployParams);
        ValidationLibrary.validateParameters(deployParams, setup);
        allUsers.add(DeployConstants.HOLESKY_DEPLOYER);
        updateSystemState();
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_ETH_Withdrawal_WSTETH()
        external
    {
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 1 ether);
        vm.startPrank(depositor1);
        uint256 lpAmount = setup.depositWrapper.deposit{value: 1 ether}(
            depositor1,
            address(0), // eth
            1 ether,
            1 ether - 3 wei, // > min lp amount
            type(uint256).max
        );
        updateSystemState();
        assertTrue(lpAmount >= 1 ether - 3 wei); // rounding errors
        vm.stopPrank();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();
        assertEq(
            stackBefore.totalSupply + lpAmount,
            stackAfter.totalSupply,
            "Invalid total supply change"
        );
        assertEq(
            stackBefore.erc20Balances[0],
            0,
            "Invalid erc20 balances before"
        );
        assertEq(
            stackAfter.erc20Balances[0],
            0,
            "Invalid erc20 balances after"
        );
        assertEq(
            stackBefore.ratiosX96Value,
            stackAfter.ratiosX96Value,
            "Invalid ratios x96 values"
        );
        assertEq(
            stackBefore.totalValue + 1 ether,
            stackAfter.totalValue,
            "Invalid total value change"
        );

        vm.prank(depositor1);
        setup.vault.registerWithdrawal(
            depositor1,
            lpAmount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );

        updateSystemState();
        {
            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.lpBalance,
                lpAmount,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                0,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance
            );
        }

        {
            (, uint256[] memory baseTvlBefore) = setup.vault.baseTvl();
            vm.prank(DeployConstants.HOLESKY_CURATOR_MANAGER);
            setup.defaultBondStrategy.processAll();
            updateSystemState();

            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid request lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                0,
                "Invalid request lp balance before withdrawal processing"
            );

            assertEq(
                userStateBefore.lpBalance,
                0,
                "Invalid user lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid user lp balance before withdrawal processing"
            );

            (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

            uint256 wstethBondIndex = DeployConstants.WSTETH >
                DeployConstants.WSTETH_DEFAULT_BOND
                ? 0
                : 1;
            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance +
                    baseTvlBefore[wstethBondIndex] -
                    baseTvlAfter[wstethBondIndex]
            );
        }
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_WETH_Withdrawal_WSTETH()
        external
    {
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 1 ether);
        vm.startPrank(depositor1);
        IWeth(DeployConstants.WETH).deposit{value: 1 ether}();
        IERC20(DeployConstants.WETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            1 ether
        );
        uint256 lpAmount = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.WETH,
            1 ether,
            1 ether - 3 wei, // > min lp amount
            type(uint256).max
        );
        updateSystemState();
        assertTrue(lpAmount >= 1 ether - 3 wei); // rounding errors
        vm.stopPrank();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();
        assertEq(
            stackBefore.totalSupply + lpAmount,
            stackAfter.totalSupply,
            "Invalid total supply change"
        );
        assertEq(
            stackBefore.erc20Balances[0],
            0,
            "Invalid erc20 balances before"
        );
        assertEq(
            stackAfter.erc20Balances[0],
            0,
            "Invalid erc20 balances after"
        );
        assertEq(
            stackBefore.ratiosX96Value,
            stackAfter.ratiosX96Value,
            "Invalid ratios x96 values"
        );
        assertEq(
            stackBefore.totalValue + 1 ether,
            stackAfter.totalValue,
            "Invalid total value change"
        );

        vm.prank(depositor1);
        setup.vault.registerWithdrawal(
            depositor1,
            lpAmount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );

        updateSystemState();
        {
            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.lpBalance,
                lpAmount,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                0,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance
            );
        }

        {
            (, uint256[] memory baseTvlBefore) = setup.vault.baseTvl();
            vm.prank(DeployConstants.HOLESKY_CURATOR_MANAGER);
            setup.defaultBondStrategy.processAll();
            updateSystemState();

            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid request lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                0,
                "Invalid request lp balance before withdrawal processing"
            );

            assertEq(
                userStateBefore.lpBalance,
                0,
                "Invalid user lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid user lp balance before withdrawal processing"
            );

            (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

            uint256 wstethBondIndex = DeployConstants.WSTETH >
                DeployConstants.WSTETH_DEFAULT_BOND
                ? 0
                : 1;
            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance +
                    baseTvlBefore[wstethBondIndex] -
                    baseTvlAfter[wstethBondIndex]
            );
        }
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_STETH_Withdrawal_WSTETH()
        external
    {
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 1 ether);
        vm.startPrank(depositor1);
        ISteth(DeployConstants.STETH).submit{value: 1 ether}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            1 ether
        );
        uint256 lpAmount = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.STETH,
            1 ether,
            1 ether - 3 wei, // > min lp amount
            type(uint256).max
        );
        updateSystemState();
        assertTrue(lpAmount >= 1 ether - 3 wei); // rounding errors
        vm.stopPrank();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();
        assertEq(
            stackBefore.totalSupply + lpAmount,
            stackAfter.totalSupply,
            "Invalid total supply change"
        );
        assertEq(
            stackBefore.erc20Balances[0],
            0,
            "Invalid erc20 balances before"
        );
        assertEq(
            stackAfter.erc20Balances[0],
            0,
            "Invalid erc20 balances after"
        );
        assertEq(
            stackBefore.ratiosX96Value,
            stackAfter.ratiosX96Value,
            "Invalid ratios x96 values"
        );
        assertEq(
            stackBefore.totalValue + 1 ether,
            stackAfter.totalValue,
            "Invalid total value change"
        );

        vm.prank(depositor1);
        setup.vault.registerWithdrawal(
            depositor1,
            lpAmount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );

        updateSystemState();
        {
            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.lpBalance,
                lpAmount,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                0,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance
            );
        }

        {
            (, uint256[] memory baseTvlBefore) = setup.vault.baseTvl();
            vm.prank(DeployConstants.HOLESKY_CURATOR_MANAGER);
            setup.defaultBondStrategy.processAll();
            updateSystemState();

            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid request lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                0,
                "Invalid request lp balance before withdrawal processing"
            );

            assertEq(
                userStateBefore.lpBalance,
                0,
                "Invalid user lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid user lp balance before withdrawal processing"
            );

            (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

            uint256 wstethBondIndex = DeployConstants.WSTETH >
                DeployConstants.WSTETH_DEFAULT_BOND
                ? 0
                : 1;
            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance +
                    baseTvlBefore[wstethBondIndex] -
                    baseTvlAfter[wstethBondIndex]
            );
        }
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_WSTETH_Withdrawal_WSTETH()
        external
    {
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 1 ether);
        vm.startPrank(depositor1);
        ISteth(DeployConstants.STETH).submit{value: 1 ether}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(DeployConstants.WSTETH),
            1 ether
        );
        IWSteth(DeployConstants.WSTETH).wrap(1 ether);
        uint256 depositAmount = IERC20(DeployConstants.WSTETH).balanceOf(
            depositor1
        );
        IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            depositAmount
        );
        uint256 lpAmount = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.WSTETH,
            depositAmount,
            1 ether - 3 wei, // > min lp amount
            type(uint256).max
        );
        updateSystemState();
        assertTrue(lpAmount >= 1 ether - 3 wei); // rounding errors
        vm.stopPrank();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();
        assertEq(
            stackBefore.totalSupply + lpAmount,
            stackAfter.totalSupply,
            "Invalid total supply change"
        );
        assertEq(
            stackBefore.erc20Balances[0],
            0,
            "Invalid erc20 balances before"
        );
        assertEq(
            stackAfter.erc20Balances[0],
            0,
            "Invalid erc20 balances after"
        );
        assertEq(
            stackBefore.ratiosX96Value,
            stackAfter.ratiosX96Value,
            "Invalid ratios x96 values"
        );
        assertEq(
            stackBefore.totalValue + 1 ether,
            stackAfter.totalValue,
            "Invalid total value change"
        );

        vm.prank(depositor1);
        setup.vault.registerWithdrawal(
            depositor1,
            lpAmount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );

        updateSystemState();
        {
            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.lpBalance,
                lpAmount,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                0,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance
            );
        }

        {
            (, uint256[] memory baseTvlBefore) = setup.vault.baseTvl();
            vm.prank(DeployConstants.HOLESKY_CURATOR_MANAGER);
            setup.defaultBondStrategy.processAll();
            updateSystemState();

            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid request lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                0,
                "Invalid request lp balance before withdrawal processing"
            );

            assertEq(
                userStateBefore.lpBalance,
                0,
                "Invalid user lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid user lp balance before withdrawal processing"
            );

            (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

            uint256 wstethBondIndex = DeployConstants.WSTETH >
                DeployConstants.WSTETH_DEFAULT_BOND
                ? 0
                : 1;
            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance +
                    baseTvlBefore[wstethBondIndex] -
                    baseTvlAfter[wstethBondIndex]
            );
            assertApproxEqAbs(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance + depositAmount,
                1 wei
            );
        }
    }

    function testRegularDepositWithdrawalScenario_DepositWithoutWrapper_WSTETH_Withdrawal_WSTETH()
        external
    {
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 1 ether);
        vm.startPrank(depositor1);
        ISteth(DeployConstants.STETH).submit{value: 1 ether}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(DeployConstants.WSTETH),
            1 ether
        );
        IWSteth(DeployConstants.WSTETH).wrap(1 ether);
        uint256 depositAmount = IERC20(DeployConstants.WSTETH).balanceOf(
            depositor1
        );
        IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
            address(setup.vault),
            depositAmount
        );
        uint256 lpAmount;
        {
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = depositAmount;
            (, lpAmount) = setup.vault.deposit(
                depositor1,
                amounts,
                1 ether - 3 wei, // > min lp amount
                type(uint256).max
            );
        }
        updateSystemState();
        assertTrue(lpAmount >= 1 ether - 3 wei); // rounding errors
        vm.stopPrank();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();
        assertEq(
            stackBefore.totalSupply + lpAmount,
            stackAfter.totalSupply,
            "Invalid total supply change"
        );
        assertEq(
            stackBefore.erc20Balances[0],
            0,
            "Invalid erc20 balances before"
        );
        assertEq(
            stackAfter.erc20Balances[0],
            0,
            "Invalid erc20 balances after"
        );
        assertEq(
            stackBefore.ratiosX96Value,
            stackAfter.ratiosX96Value,
            "Invalid ratios x96 values"
        );
        assertEq(
            stackBefore.totalValue + 1 ether,
            stackAfter.totalValue,
            "Invalid total value change"
        );

        vm.prank(depositor1);
        setup.vault.registerWithdrawal(
            depositor1,
            lpAmount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );

        updateSystemState();
        {
            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.lpBalance,
                lpAmount,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid lp balance after withdrawal request"
            );
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                0,
                "Invalid lp balance before withdrawal request"
            );

            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance
            );
        }

        {
            (, uint256[] memory baseTvlBefore) = setup.vault.baseTvl();
            vm.prank(DeployConstants.HOLESKY_CURATOR_MANAGER);
            setup.defaultBondStrategy.processAll();
            updateSystemState();

            UserState memory userStateAfter = usersSystemState[epoch - 1][
                depositor1
            ];
            UserState memory userStateBefore = usersSystemState[epoch - 2][
                depositor1
            ];
            assertEq(
                userStateBefore.withdrawalRequest.lpAmount,
                lpAmount,
                "Invalid request lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.withdrawalRequest.lpAmount,
                0,
                "Invalid request lp balance before withdrawal processing"
            );

            assertEq(
                userStateBefore.lpBalance,
                0,
                "Invalid user lp balance after withdrawal processing"
            );
            assertEq(
                userStateAfter.lpBalance,
                0,
                "Invalid user lp balance before withdrawal processing"
            );

            (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

            uint256 wstethBondIndex = DeployConstants.WSTETH >
                DeployConstants.WSTETH_DEFAULT_BOND
                ? 0
                : 1;
            assertEq(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance +
                    baseTvlBefore[wstethBondIndex] -
                    baseTvlAfter[wstethBondIndex]
            );
            assertApproxEqAbs(
                userStateAfter.wstethBalance,
                userStateBefore.wstethBalance + depositAmount,
                1 wei
            );
        }
    }
}
