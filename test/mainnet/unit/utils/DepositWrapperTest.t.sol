// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        assertNotEq(address(wrapper), address(0));
        assertEq(address(wrapper.vault()), address(vault));
        assertEq(address(wrapper.steth()), address(Constants.STETH));
        assertEq(address(wrapper.wsteth()), address(Constants.WSTETH));
        assertEq(address(wrapper.weth()), address(Constants.WETH));
    }

    function testDepositFailsWithInvalidTokenList() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        uint256 amount = 100;

        vm.startPrank(sender);
        vault.setUnderlyingTokens(new address[](0));

        vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
        wrapper.deposit(sender, Constants.WSTETH, amount, amount, 0);

        vault.setUnderlyingTokens(new address[](1));
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
        wrapper.deposit(sender, Constants.WSTETH, amount, amount, 0);

        vm.stopPrank();
    }

    function testDepositFailsWithInvalidAmount() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        wrapper.deposit(sender, Constants.USDT, 0, 0, 0);

        vm.stopPrank();
    }

    function testDepositFailsWithInvalidToken() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        wrapper.deposit(sender, Constants.USDT, 1, 1, 0);

        vm.stopPrank();
    }

    function testDepositWsteth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(Constants.WSTETH, sender, amount);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(wrapper),
            amount
        );

        wrapper.deposit(sender, Constants.WSTETH, amount, amount, 0);

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), amount);
        assertEq(IERC20(Constants.WSTETH).balanceOf(address(wrapper)), 0);

        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount);
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);

        vm.stopPrank();
    }

    function testDepositSteth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(Constants.WSTETH, sender, amount);
        IWSteth(Constants.WSTETH).unwrap(amount);
        amount = IERC20(Constants.STETH).balanceOf(sender);
        IERC20(Constants.STETH).safeIncreaseAllowance(address(wrapper), amount);

        wrapper.deposit(sender, Constants.STETH, amount, amount, 0);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            1 ether - 2 wei
        ); // b.o. two steth transfers
        assertEq(IERC20(Constants.STETH).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount); // exact mocked amount
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);
        vm.stopPrank();
    }

    function testDepositWeth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(Constants.WETH, sender, amount);
        IERC20(Constants.WETH).safeIncreaseAllowance(address(wrapper), amount);

        wrapper.deposit(sender, Constants.WETH, amount, amount, 0);
        if (block.number == 19762100) {
            assertEq(
                IERC20(Constants.WSTETH).balanceOf(address(vault)),
                858250265580573998
            ); // b.o. fetched for block
        }
        assertTrue(
            IERC20(Constants.WSTETH).balanceOf(address(vault)) >=
                (amount * 8) / 10
        );
        assertEq(IERC20(Constants.WETH).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount); // exact mocked amount
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);
        vm.stopPrank();
    }

    function testDepositEth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(sender, amount);

        wrapper.deposit{value: amount}(sender, address(0), amount, amount, 0);
        if (block.number == 19762100) {
            assertEq(
                IERC20(Constants.WSTETH).balanceOf(address(vault)),
                858250265580573998
            ); // b.o. fetched for block
        }
        assertTrue(
            IERC20(Constants.WSTETH).balanceOf(address(vault)) >=
                (amount * 8) / 10
        );
        assertEq(IERC20(Constants.WETH).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount); // exact mocked amount
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);
        vm.stopPrank();
    }

    function testDepositWstethWithDust() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);
        uint256[] memory dust = new uint256[](1);
        dust[0] = 123 wei;
        vault.setDust(dust);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(Constants.WSTETH, sender, amount);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(wrapper),
            amount
        );

        wrapper.deposit(sender, Constants.WSTETH, amount, amount, 0);

        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            amount - dust[0]
        );
        assertEq(IERC20(Constants.WSTETH).balanceOf(address(wrapper)), 0);

        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount);
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);

        vm.stopPrank();
    }

    function testView() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        assertNotEq(wrapper.weth(), address(0));
        assertNotEq(wrapper.steth(), address(0));
        assertNotEq(wrapper.wsteth(), address(0));
        assertNotEq(address(wrapper.vault()), address(0));
    }

    function testReceiveFails() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        deal(sender, 1 ether);

        // vm.expectRevert(abi.encodeWithSignature("InvalidSender()")
        vm.expectRevert();
        payable(address(wrapper)).transfer(1 ether);
        vm.stopPrank();
        // vm.expectRevert(abi.encodeWithSignature("InvalidSender()"));
        // (bool success, bytes memory response) = payable(address(wrapper)).call{value: 1 ether}("");
        // assertTrue(success);
        // assertNotEq(response.length, 0);

        // vm.expectRevert(abi.encodeWithSignature("InvalidSender()"));
        // (success, response) = payable(address(wrapper)).call{value: 1 ether}("something");
        // assertFalse(success);
        // assertNotEq(response.length, 0);

        vm.stopPrank();
    }

    function testDepositEmpty() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );
        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);
        deal(sender, 1 wei);
        vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
        wrapper.deposit{value: 1 wei}(address(0), address(0), 0, 0, 0);
        vm.stopPrank();
    }

    function testReceiveOnBehalfOfWeth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = Constants.WETH;
        vm.startPrank(sender);
        deal(sender, 1 ether);
        payable(address(wrapper)).transfer(1 ether);
        vm.stopPrank();
    }

    function testDepositStethWithDust() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);
        uint256[] memory dust = new uint256[](1);
        dust[0] = 123 wei;
        vault.setDust(dust);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(Constants.WSTETH, sender, amount);
        IWSteth(Constants.WSTETH).unwrap(amount);
        amount = IERC20(Constants.STETH).balanceOf(sender);
        IERC20(Constants.STETH).safeIncreaseAllowance(address(wrapper), amount);

        wrapper.deposit(sender, Constants.STETH, amount, amount, 0);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            1 ether - 2 wei - dust[0]
        ); // b.o. two steth transfers
        assertEq(IERC20(Constants.STETH).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount); // exact mocked amount
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);
        vm.stopPrank();
    }

    function testDepositWethWithDust() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);
        uint256[] memory dust = new uint256[](1);
        dust[0] = 123 wei;
        vault.setDust(dust);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(Constants.WETH, sender, amount);
        IERC20(Constants.WETH).safeIncreaseAllowance(address(wrapper), amount);

        wrapper.deposit(sender, Constants.WETH, amount, amount, 0);
        if (block.number == 19762100) {
            assertEq(
                IERC20(Constants.WSTETH).balanceOf(address(vault)),
                858250265580573998 - dust[0]
            ); // b.o. fetched for block
        }
        assertTrue(
            IERC20(Constants.WSTETH).balanceOf(address(vault)) >=
                (amount * 8) / 10
        );
        assertEq(IERC20(Constants.WETH).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount); // exact mocked amount
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);
        vm.stopPrank();
    }

    function testDepositEthWithDust() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);
        uint256[] memory dust = new uint256[](1);
        dust[0] = 123 wei;
        vault.setDust(dust);

        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        address sender = address(bytes20(keccak256("sender")));
        vm.startPrank(sender);

        uint256 amount = 1 ether;
        deal(sender, amount);

        wrapper.deposit{value: amount}(sender, address(0), amount, amount, 0);
        if (block.number == 19762100) {
            assertEq(
                IERC20(Constants.WSTETH).balanceOf(address(vault)),
                858250265580573998 - dust[0]
            ); // b.o. fetched for block
        }
        assertTrue(
            IERC20(Constants.WSTETH).balanceOf(address(vault)) >=
                (amount * 8) / 10
        );
        assertEq(IERC20(Constants.WETH).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(address(vault)).balanceOf(address(sender)), amount); // exact mocked amount
        assertEq(IERC20(address(vault)).balanceOf(address(wrapper)), 0);
        vm.stopPrank();
    }
}
