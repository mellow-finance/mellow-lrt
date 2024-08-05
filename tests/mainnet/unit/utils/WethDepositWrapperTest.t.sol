// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

// import "../../Constants.sol";

// import "../../../../src/utils/WethDepositWrapper.sol";

// contract Unit is Test {
//     using SafeERC20 for IERC20;

//     function testConstructor() external {
//         address admin = address(bytes20(keccak256("vault-admin")));
//         VaultMock vault = new VaultMock(admin);

//         WethDepositWrapper wrapper = new WethDepositWrapper(
//             IVault(address(vault)),
//             Constants.WETH
//         );

//         assertNotEq(address(wrapper), address(0));
//         assertEq(address(wrapper.vault()), address(vault));
//         assertEq(address(wrapper.weth()), address(Constants.WETH));
//     }

//     function testDepositFailsWithInvalidTokenList() external {
//         address admin = address(bytes20(keccak256("vault-admin")));
//         VaultMock vault = new VaultMock(admin);

//         WethDepositWrapper wrapper = new WethDepositWrapper(
//             IVault(address(vault)),
//             Constants.WETH
//         );

//         address sender = address(bytes20(keccak256("sender")));
//         uint256 amount = 100;

//         vm.startPrank(sender);
//         vault.setUnderlyingTokens(new address[](0));

//         vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
//         wrapper.deposit(sender, Constants.WETH, amount, amount, 0, 0);
//         vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
//         wrapper.deposit(sender, address(0), amount, amount, 0, 0);

//         vault.setUnderlyingTokens(new address[](1));
//         vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
//         wrapper.deposit(sender, Constants.WETH, amount, amount, 0, 0);
//         vm.expectRevert(abi.encodeWithSignature("InvalidTokenList()"));
//         wrapper.deposit(sender, address(0), amount, amount, 0, 0);

//         vm.stopPrank();
//     }

//     function testDepositFailsWithInvalidAmount() external {
//         address admin = address(bytes20(keccak256("vault-admin")));
//         VaultMock vault = new VaultMock(admin);
//         address[] memory underlyingTokens = new address[](2);
//         underlyingTokens[0] = Constants.WETH;
//         underlyingTokens[1] = Constants.WSTETH;
//         vault.setUnderlyingTokens(underlyingTokens);

//         WethDepositWrapper wrapper = new WethDepositWrapper(
//             IVault(address(vault)),
//             Constants.WETH
//         );

//         address sender = address(bytes20(keccak256("sender")));
//         vm.startPrank(sender);

//         vm.expectRevert(abi.encodeWithSignature("InvalidAmount()"));
//         wrapper.deposit(sender, Constants.WETH, 0, 0, 0, 0);

//         vm.stopPrank();
//     }

//     function testWeth() external {
//         address admin = address(bytes20(keccak256("vault-admin")));
//         VaultMock vault = new VaultMock(admin);
//         vault.setCoef(1e9);
//         WethDepositWrapper wrapper = new WethDepositWrapper(
//             IVault(address(vault)),
//             Constants.WETH
//         );

//         address[] memory tokens = new address[](2);
//         tokens[0] = Constants.WETH;
//         tokens[1] = Constants.WSTETH;
//         vault.setUnderlyingTokens(tokens);

//         address user = vm.createWallet("Random-user").addr;

//         vm.startPrank(user);
//         deal(Constants.WETH, user, 1 ether);
//         IERC20(Constants.WETH).safeIncreaseAllowance(
//             address(wrapper),
//             1 ether
//         );
//         wrapper.deposit{value: 0}(
//             user,
//             Constants.WETH,
//             1 ether,
//             1 ether,
//             type(uint256).max,
//             0
//         );

//         require(vault.balanceOf(user) == 1 ether);

//         vm.stopPrank();
//     }

//     function testEth() external {
//         address admin = address(bytes20(keccak256("vault-admin")));
//         VaultMock vault = new VaultMock(admin);
//         vault.setCoef(1e9);
//         WethDepositWrapper wrapper = new WethDepositWrapper(
//             IVault(address(vault)),
//             Constants.WETH
//         );

//         address[] memory tokens = new address[](2);
//         tokens[0] = Constants.WETH;
//         tokens[1] = Constants.WSTETH;
//         vault.setUnderlyingTokens(tokens);

//         address user = vm.createWallet("Random-user").addr;

//         vm.startPrank(user);
//         deal(user, 1 ether);
//         wrapper.deposit{value: 1 ether}(
//             user,
//             address(0),
//             1 ether,
//             1 ether,
//             type(uint256).max,
//             0
//         );

//         require(vault.balanceOf(user) == 1 ether);

//         vm.stopPrank();
//     }

// }
