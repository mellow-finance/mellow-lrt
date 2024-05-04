// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testContructor() external {
        ERC20TvlModule module = new ERC20TvlModule();
        assertNotEq(address(module), address(0));
    }

    function testTvlEmpty() external {
        ERC20TvlModule module = new ERC20TvlModule();
        VaultMock vault = new VaultMock(address(this));

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 0);
    }

    function testTvlZero() external {
        ERC20TvlModule module = new ERC20TvlModule();
        VaultMock vault = new VaultMock(address(this));
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(tokens);

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 1);
        assertEq(data[0].token, Constants.WSTETH);
        assertEq(data[0].amount, 0);
        assertEq(data[0].underlyingToken, Constants.WSTETH);
        assertEq(data[0].underlyingAmount, 0);
        assertFalse(data[0].isDebt);
    }

    function testTvlSingleToken() external {
        ERC20TvlModule module = new ERC20TvlModule();
        VaultMock vault = new VaultMock(address(this));
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.WSTETH;
        vault.setUnderlyingTokens(tokens);

        deal(Constants.WSTETH, address(vault), 1 ether);

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 1);
        assertEq(data[0].token, Constants.WSTETH);
        assertEq(data[0].amount, 1 ether);
        assertEq(data[0].underlyingToken, Constants.WSTETH);
        assertEq(data[0].underlyingAmount, 1 ether);
        assertFalse(data[0].isDebt);
    }

    function testTvlMultipleTokens() external {
        ERC20TvlModule module = new ERC20TvlModule();
        VaultMock vault = new VaultMock(address(this));
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.USDC;

        vault.setUnderlyingTokens(tokens);

        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.USDC, address(vault), 10 gwei);

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 2);
        assertEq(data[0].token, Constants.WSTETH);
        assertEq(data[0].amount, 1 ether);
        assertEq(data[0].underlyingToken, Constants.WSTETH);
        assertEq(data[0].underlyingAmount, 1 ether);
        assertFalse(data[0].isDebt);

        assertEq(data[1].token, Constants.USDC);
        assertEq(data[1].amount, 10 gwei);
        assertEq(data[1].underlyingToken, Constants.USDC);
        assertEq(data[1].underlyingAmount, 10 gwei);
        assertFalse(data[1].isDebt);
    }

    function testTvlDelegateCall() external {
        ERC20TvlModule module = new ERC20TvlModule();
        VaultMock vault = new VaultMock(address(this));

        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSignature("tvl(address)", address(vault))
        );
        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("Forbidden()"));
    }

    function testTvlMultipleChanges() external {
        ERC20TvlModule module = new ERC20TvlModule();
        VaultMock vault = new VaultMock(address(this));
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.WSTETH;

        vault.setUnderlyingTokens(tokens);

        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.USDC, address(vault), 10 gwei);

        {
            ITvlModule.Data[] memory data = module.tvl(address(vault));
            assertEq(data.length, 1);
            assertEq(data[0].token, Constants.WSTETH);
            assertEq(data[0].amount, 1 ether);
            assertEq(data[0].underlyingToken, Constants.WSTETH);
            assertEq(data[0].underlyingAmount, 1 ether);
            assertFalse(data[0].isDebt);
        }

        tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.USDC;
        vault.setUnderlyingTokens(tokens);

        {
            ITvlModule.Data[] memory data = module.tvl(address(vault));
            assertEq(data.length, 2);
            assertEq(data[0].token, Constants.WSTETH);
            assertEq(data[0].amount, 1 ether);
            assertEq(data[0].underlyingToken, Constants.WSTETH);
            assertEq(data[0].underlyingAmount, 1 ether);
            assertFalse(data[0].isDebt);

            assertEq(data[1].token, Constants.USDC);
            assertEq(data[1].amount, 10 gwei);
            assertEq(data[1].underlyingToken, Constants.USDC);
            assertEq(data[1].underlyingAmount, 10 gwei);
            assertFalse(data[1].isDebt);
        }
    }
}
