// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";
import "../unit/VaultTestCommon.t.sol";

/*
*/
contract VaultTestE2E is VaultTestCommon  {
    using SafeERC20 for IERC20;

    /// @dev test full cycle deposit then withdraw in regular way
    /// @notice test checks balances at all stages and 
    /// checks revert when depositor trying to withdraw having zero remaining balance
    function testDepositAndWithdrawRegular() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
        assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);
        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(depositor), 10 ether);
        vm.stopPrank();

        uint256[] memory minAmounts = amounts;
        vm.startPrank(depositor);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertTrue(isWithdrawalPossible);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 1);
            assertEq(withdrawers[0], depositor);
        }

        vm.startPrank(operator);
        address[] memory users = new address[](1);
        users[0] = depositor;
        vault.processWithdrawals(users);
        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
        }
        assertEq(IERC20(Constants.RETH).balanceOf(depositor), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(depositor), 0);
        assertEq(IERC20(Constants.WSTETH).balanceOf(depositor), 10 ether);
        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 10 gwei);

        bool[] memory statuses = vault.processWithdrawals(users);
        assertEq(statuses.length, 1);
        assertEq(statuses[0], false);
        vm.stopPrank();

        vm.startPrank(depositor);
        vm.expectRevert(abi.encodeWithSignature("ValueZero()"));
        vault.registerWithdrawal(
            depositor,
            1 wei,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();
    }

    /// @dev test deposit then request and emergency withdrawal
    /// @notice test checks balances and possibilities to process
    /// depositor does two requests, the second one is override the first
    // and then does emergency withdrawal
    function testDepositAndWithdrawRegularThenEmergency() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = amounts;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
        
        assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);
        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(depositor), 10 ether);
        vm.stopPrank();

        vm.startPrank(depositor);
        minAmounts[0] = 7;
        vault.registerWithdrawal(
            depositor,
            7 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertTrue(isWithdrawalPossible);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 1);
            assertEq(withdrawers[0], depositor);
        }

        minAmounts[0] = 10;
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            true
        );

        vault.emergencyWithdraw(new uint256[](3), type(uint256).max);
        vm.stopPrank();

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
        }

        assertEq(IERC20(Constants.RETH).balanceOf(depositor), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(depositor), 0);
        assertEq(IERC20(Constants.WSTETH).balanceOf(depositor), 10 ether);
        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 10 gwei);
    }
}