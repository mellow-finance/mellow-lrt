// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testDepositFailsWithInvalidTokenList() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testDepositFailsWithInvalidAmount() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testDepositFailsWithInvalidToken() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 0);
    }

    function testDepositWsteth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 10);

        Constants.validateDealLogs(
            e[0],
            e[1],
            address(this),
            Constants.WSTETH,
            address(sender),
            amount
        );
        Constants.validateApprovalLogs(
            e[2],
            sender,
            Constants.WSTETH,
            address(wrapper),
            amount
        );
        Constants.validateTransferLogs(
            e[3],
            sender,
            Constants.WSTETH,
            address(wrapper),
            amount
        );
        Constants.validateApprovalLogs(
            e[4],
            sender,
            Constants.WSTETH,
            address(wrapper),
            0
        );
        Constants.validateApprovalLogs(
            e[5],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            amount
        );
        Constants.validateTransferLogs(
            e[6],
            address(0),
            address(vault),
            address(sender),
            amount
        );
        Constants.validateTransferLogs(
            e[7],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            amount
        );
        Constants.validateApprovalLogs(
            e[8],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            0
        );

        assertEq(e[9].emitter, address(wrapper));
        assertEq(e[9].topics.length, 2);
        assertEq(
            e[9].topics[0],
            IDepositWrapper.DepositWrapperDeposit.selector
        );
        assertEq(e[9].topics[1], bytes32(uint256(uint160(sender))));
        assertEq(
            e[9].data,
            abi.encode(Constants.WSTETH, amount, uint256(0), uint256(0))
        );
    }

    function testDepositSteth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 19);

        Constants.validateDealLogs(
            e[0],
            e[1],
            address(this),
            Constants.WSTETH,
            address(sender),
            1 ether
        );
        Constants.validateTransferLogs(
            e[2],
            sender,
            Constants.WSTETH,
            address(0),
            1 ether
        );
        Constants.validateTransferLogs(
            e[3],
            Constants.WSTETH,
            Constants.STETH,
            address(sender),
            IWSteth(Constants.WSTETH).getStETHByWstETH(1 ether)
        );
        Constants.validateTransferSharesLogs(
            e[4],
            Constants.WSTETH,
            Constants.STETH,
            sender,
            1 ether - 1 wei // rounding error == 1 wei
        );

        Constants.validateApprovalLogs(
            e[5],
            sender,
            Constants.STETH,
            address(wrapper),
            amount
        );

        Constants.validateApprovalLogs(
            e[6],
            sender,
            Constants.STETH,
            address(wrapper),
            0
        );

        Constants.validateTransferLogs(
            e[7],
            sender,
            Constants.STETH,
            address(wrapper),
            amount
        );

        Constants.validateTransferSharesLogs(
            e[8],
            sender,
            Constants.STETH,
            address(wrapper),
            1 ether - 2 wei // rounding error == 2 weis
        );

        Constants.validateApprovalLogs(
            e[9],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            amount
        );

        Constants.validateTransferLogs(
            e[10],
            address(0),
            Constants.WSTETH,
            address(wrapper),
            1 ether - 2 wei // rounding error == 2 weis
        );

        Constants.validateApprovalLogs(
            e[11],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            0
        );

        Constants.validateTransferLogs(
            e[12],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            amount
        );

        Constants.validateTransferSharesLogs(
            e[13],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            1 ether - 2 wei // rounding error == 2 weis
        );

        Constants.validateApprovalLogs(
            e[14],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            1 ether - 2 wei // rounding error == 2 weis
        );

        Constants.validateTransferLogs(
            e[15],
            address(0),
            address(vault),
            address(sender),
            amount
        );
        Constants.validateTransferLogs(
            e[16],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            1 ether - 2 wei // rounding error == 2 weis
        );
        Constants.validateApprovalLogs(
            e[17],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            0
        );

        assertEq(e[18].emitter, address(wrapper));
        assertEq(e[18].topics.length, 2);
        assertEq(
            e[18].topics[0],
            IDepositWrapper.DepositWrapperDeposit.selector
        );
        assertEq(e[18].topics[1], bytes32(uint256(uint160(sender))));
        assertEq(
            e[18].data,
            abi.encode(Constants.STETH, 1 ether - 2 wei, uint256(0), uint256(0))
        );
    }

    function testDepositWeth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 18);

        Constants.validateDealLogs(
            e[0],
            e[1],
            address(this),
            Constants.WETH,
            address(sender),
            amount,
            3
        );
        Constants.validateApprovalLogs(
            e[2],
            sender,
            Constants.WETH,
            address(wrapper),
            amount
        );

        // WETH has no event for allowance decrease
        Constants.validateTransferLogs(
            e[3],
            sender,
            Constants.WETH,
            address(wrapper),
            amount
        );

        assertEq(e[4].emitter, Constants.WETH);
        assertEq(e[4].topics.length, 2);
        assertEq(e[4].topics[0], keccak256("Withdrawal(address,uint256)"));
        assertEq(e[4].topics[1], bytes32(uint256(uint160(address(wrapper)))));
        assertEq(e[4].data, abi.encode(amount));

        assertEq(e[5].emitter, Constants.STETH);
        assertEq(e[5].topics.length, 2);
        assertEq(
            e[5].topics[0],
            keccak256("Submitted(address,uint256,address)")
        );
        assertEq(e[5].topics[1], bytes32(uint256(uint160(address(wrapper)))));
        assertEq(e[5].data, abi.encode(amount, address(0)));

        Constants.validateTransferLogs(
            e[6],
            address(0),
            Constants.STETH,
            address(wrapper),
            amount - 1 wei // rounding error == 1 wei
        );

        Constants.validateTransferSharesLogs(
            e[7],
            address(0),
            Constants.STETH,
            address(wrapper),
            IWSteth(Constants.WSTETH).getWstETHByStETH(amount)
        );

        Constants.validateApprovalLogs(
            e[8],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            amount
        );

        uint256 expectedWstethAmount = IWSteth(Constants.WSTETH)
            .getWstETHByStETH(amount);
        Constants.validateTransferLogs(
            e[9],
            address(0),
            Constants.WSTETH,
            address(wrapper),
            expectedWstethAmount
        );

        Constants.validateApprovalLogs(
            e[10],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            0
        );

        Constants.validateTransferLogs(
            e[11],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            amount
        );

        Constants.validateTransferSharesLogs(
            e[12],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            expectedWstethAmount
        );

        Constants.validateApprovalLogs(
            e[13],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            expectedWstethAmount
        );

        Constants.validateTransferLogs(
            e[14],
            address(0),
            address(vault),
            address(sender),
            amount
        );
        Constants.validateTransferLogs(
            e[15],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            expectedWstethAmount
        );
        Constants.validateApprovalLogs(
            e[16],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            0
        );

        assertEq(e[17].emitter, address(wrapper));
        assertEq(e[17].topics.length, 2);
        assertEq(
            e[17].topics[0],
            IDepositWrapper.DepositWrapperDeposit.selector
        );
        assertEq(e[17].topics[1], bytes32(uint256(uint160(sender))));
        assertEq(
            e[17].data,
            abi.encode(
                Constants.WETH,
                expectedWstethAmount,
                uint256(0),
                uint256(0)
            )
        );
    }

    function testDepositEth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory underlyingTokens = new address[](1);
        underlyingTokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(underlyingTokens);
        vault.setCoef(1e9);

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 13);

        assertEq(e[0].emitter, Constants.STETH);
        assertEq(e[0].topics.length, 2);
        assertEq(
            e[0].topics[0],
            keccak256("Submitted(address,uint256,address)")
        );
        assertEq(e[0].topics[1], bytes32(uint256(uint160(address(wrapper)))));
        assertEq(e[0].data, abi.encode(amount, address(0)));

        Constants.validateTransferLogs(
            e[1],
            address(0),
            Constants.STETH,
            address(wrapper),
            amount - 1 wei // rounding error == 1 wei
        );

        Constants.validateTransferSharesLogs(
            e[2],
            address(0),
            Constants.STETH,
            address(wrapper),
            IWSteth(Constants.WSTETH).getWstETHByStETH(amount)
        );

        Constants.validateApprovalLogs(
            e[3],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            amount
        );

        uint256 expectedWstethAmount = IWSteth(Constants.WSTETH)
            .getWstETHByStETH(amount);
        Constants.validateTransferLogs(
            e[4],
            address(0),
            Constants.WSTETH,
            address(wrapper),
            expectedWstethAmount
        );

        Constants.validateApprovalLogs(
            e[5],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            0
        );

        Constants.validateTransferLogs(
            e[6],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            amount
        );

        Constants.validateTransferSharesLogs(
            e[7],
            address(wrapper),
            Constants.STETH,
            Constants.WSTETH,
            expectedWstethAmount
        );

        Constants.validateApprovalLogs(
            e[8],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            expectedWstethAmount
        );

        Constants.validateTransferLogs(
            e[9],
            address(0),
            address(vault),
            address(sender),
            amount
        );
        Constants.validateTransferLogs(
            e[10],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            expectedWstethAmount
        );
        Constants.validateApprovalLogs(
            e[11],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            0
        );

        assertEq(e[12].emitter, address(wrapper));
        assertEq(e[12].topics.length, 2);
        assertEq(
            e[12].topics[0],
            IDepositWrapper.DepositWrapperDeposit.selector
        );
        assertEq(e[12].topics[1], bytes32(uint256(uint160(sender))));
        assertEq(
            e[12].data,
            abi.encode(address(0), expectedWstethAmount, uint256(0), uint256(0))
        );
    }

    function testDepositEthFailsWithInvalidAmount() external {
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

        vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
        wrapper.deposit{value: amount - 1}(
            sender,
            address(0),
            amount,
            amount,
            0
        );
    }

    function testVault() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        assertEq(address(wrapper.vault()), address(vault));
    }

    function testWeth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        assertEq(wrapper.weth(), address(Constants.WETH));
    }

    function testSteth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        assertEq(wrapper.steth(), address(Constants.STETH));
    }

    function testWsteth() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(vault)),
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH
        );

        assertEq(wrapper.wsteth(), address(Constants.WSTETH));
    }

    function testConstructorZeroAddresses() external {
        DepositWrapper wrapper = new DepositWrapper(
            IVault(address(0)),
            address(0),
            address(0),
            address(0)
        );
        assertEq(address(wrapper.vault()), address(0));
        assertEq(wrapper.weth(), address(0));
        assertEq(wrapper.steth(), address(0));
        assertEq(wrapper.wsteth(), address(0));
        assertNotEq(address(wrapper), address(0));
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

        vm.recordLogs();
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

        Vm.Log[] memory e = vm.getRecordedLogs();
        assertEq(e.length, 11);

        Constants.validateDealLogs(
            e[0],
            e[1],
            address(this),
            Constants.WSTETH,
            address(sender),
            amount
        );
        Constants.validateApprovalLogs(
            e[2],
            sender,
            Constants.WSTETH,
            address(wrapper),
            amount
        );
        Constants.validateTransferLogs(
            e[3],
            sender,
            Constants.WSTETH,
            address(wrapper),
            amount
        );
        Constants.validateApprovalLogs(
            e[4],
            sender,
            Constants.WSTETH,
            address(wrapper),
            0
        );
        Constants.validateApprovalLogs(
            e[5],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            amount
        );
        Constants.validateTransferLogs(
            e[6],
            address(0),
            address(vault),
            address(sender),
            amount
        );
        Constants.validateTransferLogs(
            e[7],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            amount - dust[0]
        );
        Constants.validateApprovalLogs(
            e[8],
            address(wrapper),
            Constants.WSTETH,
            address(vault),
            dust[0]
        );

        Constants.validateTransferLogs(
            e[9],
            address(wrapper),
            Constants.WSTETH,
            address(sender),
            dust[0]
        );

        assertEq(e[10].emitter, address(wrapper));
        assertEq(e[10].topics.length, 2);
        assertEq(
            e[10].topics[0],
            IDepositWrapper.DepositWrapperDeposit.selector
        );
        assertEq(e[10].topics[1], bytes32(uint256(uint160(sender))));
        assertEq(
            e[10].data,
            abi.encode(Constants.WSTETH, amount, uint256(0), uint256(0))
        );
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
