// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    address public immutable admin =
        address(bytes20(keccak256("mellow-vault-admin")));

    function testConstructor() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vault.requireAdmin(admin);
        assertEq(vault.name(), "Mellow LRT Vault");
        assertEq(vault.symbol(), "mLRT");
        assertEq(vault.decimals(), 18);
        assertNotEq(address(vault.configurator()), address(0));
    }

    function testAddToken() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        address[] memory underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 0);

        vm.prank(admin);
        vault.addToken(Constants.WETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 1);
        assertEq(underlyingTokens[0], Constants.WETH); // [WETH]

        vm.prank(admin);
        vault.addToken(Constants.WSTETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 2);
        assertEq(underlyingTokens[0], Constants.WSTETH); // [WSTETH, WETH]

        vm.prank(admin);
        vault.addToken(Constants.STETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 3);
        assertEq(underlyingTokens[1], Constants.STETH); // [WSTETH, STETH, WETH]

        vm.prank(admin);
        vault.addToken(Constants.USDT);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 4);
        assertEq(underlyingTokens[3], Constants.USDT); // [WSTETH, STETH, WETH, USDT]

        vm.prank(admin);
        vault.addToken(Constants.RETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 5);
        assertEq(underlyingTokens[1], Constants.RETH); // [WSTETH, RETH, STETH, WETH, USDT]

        address[5] memory targetArray = [
            Constants.WSTETH,
            Constants.RETH,
            Constants.STETH,
            Constants.WETH,
            Constants.USDT
        ];

        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            assertEq(underlyingTokens[i], targetArray[i]);
        }
    }
}
