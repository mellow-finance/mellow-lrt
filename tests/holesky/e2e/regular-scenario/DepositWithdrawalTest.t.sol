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

    uint256 public MAX_ROUNDING_ERROR_PER_DEPOSIT = 3 wei;
    uint256 public TEST_DEPOSIT_AMOUNT_ETH = 1 ether;

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

    function _depositVaultWSTETH(
        address from,
        uint256 depositAmountETH
    ) private returns (uint256 lpAmount, uint256 depositAmount) {
        vm.startPrank(from);
        ISteth(DeployConstants.STETH).submit{value: depositAmountETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(DeployConstants.WSTETH),
            depositAmountETH
        );
        IWSteth(DeployConstants.WSTETH).wrap(depositAmountETH);
        depositAmount = IERC20(DeployConstants.WSTETH).balanceOf(
            from
        );
        IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
            address(setup.vault),
            depositAmount
        );
        {
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = depositAmount;
            (, lpAmount) = setup.vault.deposit(
                from,
                amounts,
                depositAmountETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
                type(uint256).max,
                0
            );
        }
        updateSystemState();
        assertTrue(lpAmount >= depositAmountETH - MAX_ROUNDING_ERROR_PER_DEPOSIT); // rounding errors
        vm.stopPrank();
    }

    function _depositWrapperETH(
        address from,
        uint256 depositAmount
    ) private returns (uint256 lpAmount) {
        vm.startPrank(from);
        lpAmount = setup.depositWrapper.deposit{value: depositAmount}(
            from,
            address(0),
            depositAmount,
            depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        assertTrue(lpAmount >= depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT); // rounding errors
        vm.stopPrank();
        return lpAmount;
    }

    function _depositWrapperWETH(
        address from,
        uint256 depositAmount
    ) private returns (uint256 lpAmount) {
        vm.startPrank(from);
        IWeth(DeployConstants.WETH).deposit{value: TEST_DEPOSIT_AMOUNT_ETH}();
        IERC20(DeployConstants.WETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            depositAmount
        );
        lpAmount = setup.depositWrapper.deposit(
            from,
            DeployConstants.WETH,
            depositAmount,
            depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        assertTrue(lpAmount >= depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT); // rounding errors
        vm.stopPrank();
    }

    function _depositWrapperSETH(
        address from,
        uint256 depositAmount
    ) private returns (uint256 lpAmount) {
        vm.startPrank(from);
        ISteth(DeployConstants.STETH).submit{value: depositAmount}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            depositAmount
        );
        lpAmount = setup.depositWrapper.deposit(
            from,
            DeployConstants.STETH,
            depositAmount,
            depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        assertTrue(lpAmount >= depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT); // rounding errors
        vm.stopPrank();
    }

    function _depositWrapperSTETH(
        address from,
        uint256 depositAmountETH
    ) private returns (uint256 lpAmount) {
        vm.startPrank(from);
        ISteth(DeployConstants.STETH).submit{value: depositAmountETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(DeployConstants.WSTETH),
            depositAmountETH
        );
        IWSteth(DeployConstants.WSTETH).wrap(depositAmountETH);
        uint256 depositAmount = IERC20(DeployConstants.WSTETH).balanceOf(
            from
        );
        IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
            address(setup.vault),
            depositAmount
        );
        {
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = depositAmount;
            (, lpAmount) = setup.vault.deposit(
                from,
                amounts,
                depositAmountETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
                type(uint256).max,
                0
            );
        }
        assertTrue(lpAmount >= depositAmountETH - MAX_ROUNDING_ERROR_PER_DEPOSIT); // rounding errors
        vm.stopPrank();
    }

    function _depositWrapperWSTETH(
        address from,
        uint256 depositAmountETH
    ) private returns (uint256 lpAmount) {
        vm.startPrank(from);
        ISteth(DeployConstants.STETH).submit{value: depositAmountETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(DeployConstants.WSTETH),
            depositAmountETH
        );
        IWSteth(DeployConstants.WSTETH).wrap(depositAmountETH);
        uint256 depositAmount = IERC20(DeployConstants.WSTETH).balanceOf(
            from
        );
        IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            depositAmount
        );
        lpAmount = setup.depositWrapper.deposit(
            from,
            DeployConstants.WSTETH,
            depositAmount,
            depositAmountETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        assertTrue(lpAmount >= depositAmountETH - MAX_ROUNDING_ERROR_PER_DEPOSIT); // rounding errors
        vm.stopPrank();
    }

    function _depositWrapperMultiToken(
        address from,
        address[] memory token,
        uint256[] memory depositAmount
    ) private returns (uint256 lpAmount) {
        assertEq(token.length, depositAmount.length, "depositMulti: length mismatch");

        for (uint256 i = 0; i < token.length; ++i) {
            if (depositAmount[i] > 0) {
                if (token[i] == address(0)) {
                    lpAmount += _depositWrapperETH(from, depositAmount[i]);
                } else if (token[i] == DeployConstants.WETH) {
                    lpAmount += _depositWrapperWETH(from, depositAmount[i]);
                } else if (token[i] == DeployConstants.STETH) {
                    lpAmount += _depositWrapperSTETH(from, depositAmount[i]);
                } else if (token[i] == DeployConstants.WSTETH) {
                    lpAmount += _depositWrapperWSTETH(from, depositAmount[i]);
                } else {
                    revert("depositMulti: wrong deposit token");
                }
            }
        }
    }

    function _checkStackBeforeAndAfter(
        IVault.ProcessWithdrawalsStack memory stackBefore,
        IVault.ProcessWithdrawalsStack memory stackAfter,
        uint256 depositAmount,
        uint256 lpAmount
    ) private view {
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
        assertGe(
            stackBefore.totalValue + depositAmount,
            stackAfter.totalValue,
            "Invalid total value rounding"
        );
        assertLe(
            stackBefore.totalValue + depositAmount - stackAfter.totalValue,
            MAX_ROUNDING_ERROR_PER_DEPOSIT,
            "Invalid total value change"
        );
    }

    function _checkUserStateBeforeWithdrawalProcessing(
        address user,
        uint256 lpAmount
    ) private view {
        UserState memory userStateAfter = usersSystemState[epoch - 1][user];
        UserState memory userStateBefore = usersSystemState[epoch - 2][
            user
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

    function _checkUserStateAfterWithdrawalProcessing(
        address user,
        uint256[] memory baseTvlBefore,
        uint256 lpAmount
    ) private view {
        UserState memory userStateAfter = usersSystemState[epoch - 1][user];
        UserState memory userStateBefore = usersSystemState[epoch - 2][
            user
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

    function _processWithdrawalAndCheck(address user, uint256 lpAmount) private  {

        vm.prank(user);
        setup.vault.registerWithdrawal(
            user,
            lpAmount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        updateSystemState();

        _checkUserStateBeforeWithdrawalProcessing(user, lpAmount);
        (, uint256[] memory baseTvlBefore) = setup.vault.baseTvl();

        vm.prank(DeployConstants.HOLESKY_CURATOR_MANAGER);
        setup.defaultBondStrategy.processAll();

        updateSystemState();

        _checkUserStateAfterWithdrawalProcessing(
            user,
            baseTvlBefore,
            lpAmount
        );
        vm.stopPrank();
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_ETH_Withdrawal_WSTETH()
        external
    {
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, TEST_DEPOSIT_AMOUNT_ETH);
        uint256 lpAmount = _depositWrapperETH(
            depositor1,
            TEST_DEPOSIT_AMOUNT_ETH
        );

        updateSystemState();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();

        _checkStackBeforeAndAfter(
            stackBefore,
            stackAfter,
            TEST_DEPOSIT_AMOUNT_ETH,
            lpAmount
        );

        _processWithdrawalAndCheck(depositor1, lpAmount);
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_WETH_Withdrawal_WSTETH()
        external
    {
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, TEST_DEPOSIT_AMOUNT_ETH);
        uint256 lpAmount = _depositWrapperWETH(depositor1, TEST_DEPOSIT_AMOUNT_ETH);

        updateSystemState();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();

        _checkStackBeforeAndAfter(
            stackBefore,
            stackAfter,
            TEST_DEPOSIT_AMOUNT_ETH,
            lpAmount
        );

        _processWithdrawalAndCheck(depositor1, lpAmount);
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_STETH_Withdrawal_WSTETH()
        external
    {
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, TEST_DEPOSIT_AMOUNT_ETH);
        uint256 lpAmount = _depositWrapperSETH(depositor1, TEST_DEPOSIT_AMOUNT_ETH);

        updateSystemState();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();

        _checkStackBeforeAndAfter(
            stackBefore,
            stackAfter,
            TEST_DEPOSIT_AMOUNT_ETH,
            lpAmount
        );

        _processWithdrawalAndCheck(depositor1, lpAmount);
    }

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_WSTETH_Withdrawal_WSTETH()
        external
    {
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, TEST_DEPOSIT_AMOUNT_ETH);
        uint256 lpAmount = _depositWrapperWSTETH(depositor1, TEST_DEPOSIT_AMOUNT_ETH);

        updateSystemState();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();

        _checkStackBeforeAndAfter(
            stackBefore,
            stackAfter,
            TEST_DEPOSIT_AMOUNT_ETH,
            lpAmount
        );

        _processWithdrawalAndCheck(depositor1, lpAmount);
    }
    
    function testRegularDepositWithdrawalScenario_DepositWithoutWrapper_WSTETH_Withdrawal_WSTETH()
        external
    {
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, TEST_DEPOSIT_AMOUNT_ETH);

        (uint256 lpAmount, uint256 depositAmount) = _depositVaultWSTETH(depositor1, TEST_DEPOSIT_AMOUNT_ETH);

        updateSystemState();

        IVault.ProcessWithdrawalsStack memory stackAfter = setup
            .vault
            .calculateStack();

        _checkStackBeforeAndAfter(
            stackBefore,
            stackAfter,
            TEST_DEPOSIT_AMOUNT_ETH,
            lpAmount
        );

        _processWithdrawalAndCheck(depositor1, lpAmount);

        UserState memory userStateAfter = usersSystemState[epoch - 1][depositor1];
        UserState memory userStateBefore = usersSystemState[epoch - 2][
            depositor1
        ];
        assertApproxEqAbs(
            userStateAfter.wstethBalance,
            userStateBefore.wstethBalance + depositAmount,
            1 wei
        );
    }
/*
    function testRegularDepositWithdrawalScenario_DepositWithWrapper_ETH_WETH_Withdrawal_WSTETH()
        external
    {
        uint256 maxRoundError = 2 * MAX_ROUNDING_ERROR_PER_DEPOSIT;
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 2 ether);
        vm.startPrank(depositor1);
        IWeth(DeployConstants.WETH).deposit{value: TEST_DEPOSIT_AMOUNT_ETH}();
        IERC20(DeployConstants.WETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        uint256 lpAmountETH = setup.depositWrapper.deposit{value: TEST_DEPOSIT_AMOUNT_ETH}(
            depositor1,
            address(0), // eth
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );

        uint256 lpAmountWETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.WETH,
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        uint256 lpAmount = lpAmountETH+lpAmountWETH;
        updateSystemState();
        assertTrue(lpAmount >= 2 ether - maxRoundError); // rounding errors (twice by MAX_ROUNDING_ERROR_PER_DEPOSIT)
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
        assertGt(
            stackBefore.totalValue + 2 ether,
            stackAfter.totalValue,
            "Invalid total value rounding"
        );
        assertLt(
            stackBefore.totalValue + 2 ether - stackAfter.totalValue,
            maxRoundError,
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

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_ETH_STETH_Withdrawal_WSTETH()
        external
    {
        uint256 maxRoundError = 2 * MAX_ROUNDING_ERROR_PER_DEPOSIT;
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 2 ether);
        vm.startPrank(depositor1);
        ISteth(DeployConstants.STETH).submit{value: TEST_DEPOSIT_AMOUNT_ETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        uint256 lpAmountETH = setup.depositWrapper.deposit{value: TEST_DEPOSIT_AMOUNT_ETH}(
            depositor1,
            address(0), // eth
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );

        uint256 lpAmountWETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.STETH,
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        uint256 lpAmount = lpAmountETH+lpAmountWETH;
        updateSystemState();
        assertTrue(lpAmount >= 2 ether - maxRoundError); // rounding errors (twice by MAX_ROUNDING_ERROR_PER_DEPOSIT)
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
        assertGt(
            stackBefore.totalValue + 2 ether,
            stackAfter.totalValue,
            "Invalid total value rounding"
        );
        assertLt(
            stackBefore.totalValue + 2 ether - stackAfter.totalValue,
            maxRoundError,
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

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_ETH_WSTETH_Withdrawal_WSTETH()
        external
    {
        uint256 maxRoundError = 2 * MAX_ROUNDING_ERROR_PER_DEPOSIT;
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 2 ether);
        vm.startPrank(depositor1);
        ISteth(DeployConstants.STETH).submit{value: TEST_DEPOSIT_AMOUNT_ETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(DeployConstants.WSTETH),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        IWSteth(DeployConstants.WSTETH).wrap(TEST_DEPOSIT_AMOUNT_ETH);
        uint256 depositAmount = IERC20(DeployConstants.WSTETH).balanceOf(
            depositor1
        );
        IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            depositAmount
        );
        uint256 lpAmountETH = setup.depositWrapper.deposit{value: TEST_DEPOSIT_AMOUNT_ETH}(
            depositor1,
            address(0), // eth
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );

        uint256 lpAmountWETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.WSTETH,
            depositAmount,
            depositAmount - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        uint256 lpAmount = lpAmountETH+lpAmountWETH;
        updateSystemState();
        assertTrue(lpAmount >= 2 ether - maxRoundError); // rounding errors (twice by MAX_ROUNDING_ERROR_PER_DEPOSIT)
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
        assertGt(
            stackBefore.totalValue + 2 ether,
            stackAfter.totalValue,
            "Invalid total value rounding"
        );
        assertLt(
            stackBefore.totalValue + 2 ether - stackAfter.totalValue,
            maxRoundError,
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

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_WETH_STETH_Withdrawal_WSTETH()
        external
    {
        uint256 maxRoundError = 2 * MAX_ROUNDING_ERROR_PER_DEPOSIT;
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 2 ether);
        vm.startPrank(depositor1);
        IWeth(DeployConstants.WETH).deposit{value: TEST_DEPOSIT_AMOUNT_ETH}();
        IERC20(DeployConstants.WETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        uint256 lpAmountETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.WETH,
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        ISteth(DeployConstants.STETH).submit{value: TEST_DEPOSIT_AMOUNT_ETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        uint256 lpAmountWETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.STETH,
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        uint256 lpAmount = lpAmountETH+lpAmountWETH;
        updateSystemState();
        assertTrue(lpAmount >= 2 ether - maxRoundError); // rounding errors (twice by MAX_ROUNDING_ERROR_PER_DEPOSIT)
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
        assertGt(
            stackBefore.totalValue + 2 ether,
            stackAfter.totalValue,
            "Invalid total value rounding"
        );
        assertLt(
            stackBefore.totalValue + 2 ether - stackAfter.totalValue,
            maxRoundError,
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

    function testRegularDepositWithdrawalScenario_DepositWithWrapper_STETH_WSTETH_Withdrawal_WSTETH()
        external
    {
        uint256 maxRoundError = 2 * MAX_ROUNDING_ERROR_PER_DEPOSIT;
        // fails due to steth-eth invalid ratio && absence of RPC error logs
        address depositor1 = addUser("depositor-1");

        IVault.ProcessWithdrawalsStack memory stackBefore = setup
            .vault
            .calculateStack();

        deal(depositor1, 2 ether);
        vm.startPrank(depositor1);
        ISteth(DeployConstants.STETH).submit{value: TEST_DEPOSIT_AMOUNT_ETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        uint256 lpAmountETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.STETH,
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        ISteth(DeployConstants.STETH).submit{value: TEST_DEPOSIT_AMOUNT_ETH}(address(0));
        IERC20(DeployConstants.STETH).safeIncreaseAllowance(
            address(setup.depositWrapper),
            TEST_DEPOSIT_AMOUNT_ETH
        );
        uint256 lpAmountWETH = setup.depositWrapper.deposit(
            depositor1,
            DeployConstants.STETH,
            TEST_DEPOSIT_AMOUNT_ETH,
            TEST_DEPOSIT_AMOUNT_ETH - MAX_ROUNDING_ERROR_PER_DEPOSIT, // > min lp amount
            type(uint256).max,
            0
        );
        uint256 lpAmount = lpAmountETH+lpAmountWETH;
        updateSystemState();
        assertTrue(lpAmount >= 2 ether - maxRoundError); // rounding errors (twice by MAX_ROUNDING_ERROR_PER_DEPOSIT)
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
        assertGt(
            stackBefore.totalValue + 2 ether,
            stackAfter.totalValue,
            "Invalid total value rounding"
        );
        assertLt(
            stackBefore.totalValue + 2 ether - stackAfter.totalValue,
            maxRoundError,
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
    // ===========================================================================
*/
}
