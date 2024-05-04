// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../Constants.sol";

import "../mocks/VaultMock.sol";
import "../mocks/DefaultBondMock.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        DefaultBondModule module = new DefaultBondModule();
        assertNotEq(address(module), address(0));
    }

    function testExternalCall() external {
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        module.deposit(address(bond), 100);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        module.withdraw(address(bond), 100);
    }

    function testDeposit() external {
        address sender = address(this);
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);

        uint256 amount = 1 ether;
        bytes memory delegateCallData = abi.encodeWithSelector(
            IDefaultBondModule.deposit.selector,
            address(bond),
            amount
        );

        deal(Constants.WSTETH, sender, amount);

        (bool success, bytes memory response) = address(module).delegatecall(
            delegateCallData
        );
        assertTrue(success);
        uint256 lpAmount = abi.decode(response, (uint256));
        assertEq(lpAmount, amount);
        assertEq(bond.balanceOf(sender), lpAmount);
    }

    function testDepositZero() external {
        address sender = address(this);
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);

        uint256 amount = 0 ether;
        bytes memory delegateCallData = abi.encodeWithSelector(
            IDefaultBondModule.deposit.selector,
            address(bond),
            amount
        );

        (bool success, bytes memory response) = address(module).delegatecall(
            delegateCallData
        );

        assertTrue(success);
        uint256 lpAmount = abi.decode(response, (uint256));
        assertEq(lpAmount, amount);
        assertEq(bond.balanceOf(sender), lpAmount);
    }

    function testDepositFail() external {
        address sender = address(this);
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);
        uint256 amount = 1 ether;
        bytes memory delegateCallData = abi.encodeWithSelector(
            IDefaultBondModule.deposit.selector,
            address(bond),
            amount
        );
        deal(Constants.WSTETH, sender, amount - 1);
        (bool success, ) = address(module).delegatecall(delegateCallData);
        assertFalse(success);
    }

    function testWithdraw() external {
        address sender = address(this);
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);

        uint256 amount = 1 ether;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IDefaultBondModule.withdraw.selector,
            address(bond),
            amount
        );

        deal(Constants.WSTETH, address(bond), amount);
        deal(address(bond), sender, amount);

        assertEq(bond.balanceOf(sender), amount);
        assertEq(IERC20(Constants.WSTETH).balanceOf(sender), 0);

        (bool success, bytes memory response) = address(module).delegatecall(
            delegateCallData
        );

        assertTrue(success);
        assertEq(response.length, 0x20);
        uint256 actualAmount = abi.decode(response, (uint256));
        assertEq(actualAmount, amount);
        assertEq(bond.balanceOf(sender), 0);
        assertEq(IERC20(Constants.WSTETH).balanceOf(sender), amount);
    }

    function testWithdrawAll() external {
        address sender = address(this);
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);

        uint256 amount = 1 ether;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IDefaultBondModule.withdraw.selector,
            address(bond),
            type(uint256).max
        );

        deal(Constants.WSTETH, address(bond), amount);
        deal(address(bond), sender, amount);

        assertEq(bond.balanceOf(sender), amount);
        assertEq(IERC20(Constants.WSTETH).balanceOf(sender), 0);

        (bool success, bytes memory response) = address(module).delegatecall(
            delegateCallData
        );
        assertTrue(success);
        assertNotEq(response.length, 0);
        uint256 actualAmount = abi.decode(response, (uint256));
        assertEq(actualAmount, amount);
        assertEq(bond.balanceOf(sender), 0);
        assertEq(IERC20(Constants.WSTETH).balanceOf(sender), amount);
    }

    function testWithdrawZero() external {
        address sender = address(this);
        DefaultBondModule module = new DefaultBondModule();
        DefaultBondMock bond = new DefaultBondMock(Constants.WSTETH);

        uint256 amount = 0;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IDefaultBondModule.withdraw.selector,
            address(bond),
            amount
        );

        deal(Constants.WSTETH, address(bond), amount);
        deal(address(bond), sender, amount);

        assertEq(bond.balanceOf(sender), amount);
        assertEq(IERC20(Constants.WSTETH).balanceOf(sender), 0);

        (bool success, bytes memory response) = address(module).delegatecall(
            delegateCallData
        );
        assertTrue(success);
        assertNotEq(response.length, 0);
        uint256 actualAmount = abi.decode(response, (uint256));
        assertEq(actualAmount, amount);
        assertEq(bond.balanceOf(sender), 0);
        assertEq(IERC20(Constants.WSTETH).balanceOf(sender), amount);
    }
}
