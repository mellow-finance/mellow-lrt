// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        ERC20SwapModule module = new ERC20SwapModule();
        assertNotEq(address(module), address(0));
    }

    function testExternalCall() external {
        ERC20SwapModule module = new ERC20SwapModule();

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        module.swap(
            IERC20SwapModule.SwapParams({
                tokenIn: address(1),
                tokenOut: address(2),
                amountIn: 100,
                minAmountOut: 90,
                deadline: block.timestamp + 100
            }),
            address(this),
            abi.encodeWithSignature("test()")
        );
    }

    function testDeadlineCheckFails() external {
        ERC20SwapModule module = new ERC20SwapModule();
        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                IERC20SwapModule.swap.selector,
                IERC20SwapModule.SwapParams({
                    tokenIn: address(1),
                    tokenOut: address(2),
                    amountIn: 100,
                    minAmountOut: 90,
                    deadline: block.timestamp - 100
                }),
                address(this),
                abi.encodeWithSignature("test()")
            )
        );
        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("Deadline()"));
    }

    function testSwapFailed() external {
        ERC20SwapModule module = new ERC20SwapModule();
        address sender = address(bytes20(keccak256("random-sender")));
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        vm.startPrank(sender);
        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                IERC20SwapModule.swap.selector,
                IERC20SwapModule.SwapParams({
                    tokenIn: Constants.WSTETH,
                    tokenOut: Constants.WETH,
                    amountIn: 1 ether,
                    minAmountOut: 1 ether,
                    deadline: type(uint256).max
                }),
                uniswapV3Router,
                abi.encodeWithSignature("invalidSignature()")
            )
        );
        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("SwapFailed()"));
        vm.stopPrank();
    }

    function testInvalidSwapAmounts() external {
        ERC20SwapModule module = new ERC20SwapModule();
        address sender = address(this);
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: Constants.WSTETH,
                tokenOut: Constants.WETH,
                amountIn: 1 ether,
                minAmountOut: 2 ether,
                deadline: type(uint256).max
            }),
            uniswapV3Router,
            abi.encodeWithSelector(
                ISwapRouter.exactInputSingle.selector,
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: Constants.WSTETH,
                    tokenOut: Constants.WETH,
                    fee: 500,
                    recipient: sender,
                    deadline: type(uint256).max,
                    amountIn: 1 ether,
                    amountOutMinimum: 1 ether,
                    sqrtPriceLimitX96: 0
                })
            )
        );

        {
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            // nothing to swap
            assertFalse(success);
            assertEq(response, abi.encodeWithSignature("SwapFailed()"));
        }

        deal(Constants.WSTETH, sender, 10 ether);
        {
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            // high slippage
            assertFalse(success);
            assertEq(response, abi.encodeWithSignature("InvalidSwapAmounts()"));
        }
    }

    function testSwapUSDT() external {
        ERC20SwapModule module = new ERC20SwapModule();
        address sender = address(this);
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        uint256 amountIn = 3500 * 1e6;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: Constants.USDT,
                tokenOut: Constants.WETH,
                amountIn: amountIn,
                minAmountOut: 1 ether,
                deadline: type(uint256).max
            }),
            uniswapV3Router,
            abi.encodeWithSelector(
                ISwapRouter.exactInputSingle.selector,
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: Constants.USDT,
                    tokenOut: Constants.WETH,
                    fee: 500,
                    recipient: sender,
                    deadline: type(uint256).max,
                    amountIn: amountIn,
                    amountOutMinimum: 1 ether,
                    sqrtPriceLimitX96: 0
                })
            )
        );

        {
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            // nothing to swap
            assertFalse(success);
            assertEq(response, abi.encodeWithSignature("SwapFailed()"));
        }

        assertEq(
            IERC20(Constants.USDT).allowance(sender, address(uniswapV3Router)),
            0
        );

        deal(Constants.USDT, sender, amountIn);
        {
            uint256 balanceBefore = IERC20(Constants.WETH).balanceOf(sender);
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            assertTrue(success);
            response = abi.decode(response, (bytes));
            uint256 addedValue = abi.decode(response, (uint256));
            uint256 balanceAfter = IERC20(Constants.WETH).balanceOf(sender);
            assertEq(balanceBefore + addedValue, balanceAfter);
        }

        assertEq(
            IERC20(Constants.USDT).allowance(sender, address(uniswapV3Router)),
            0
        );

        deal(Constants.USDT, sender, amountIn);
        IERC20(Constants.USDT).safeIncreaseAllowance(uniswapV3Router, 1 wei);

        assertEq(
            IERC20(Constants.USDT).allowance(sender, address(uniswapV3Router)),
            1 wei
        );

        deal(Constants.USDT, sender, amountIn);
        {
            uint256 balanceBefore = IERC20(Constants.WETH).balanceOf(sender);
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            assertTrue(success);
            response = abi.decode(response, (bytes));
            uint256 addedValue = abi.decode(response, (uint256));
            uint256 balanceAfter = IERC20(Constants.WETH).balanceOf(sender);
            assertEq(balanceBefore + addedValue, balanceAfter);
        }

        assertEq(
            IERC20(Constants.USDT).allowance(sender, address(uniswapV3Router)),
            0
        );
    }

    function testSwapStethToWSteth() external {
        ERC20SwapModule module = new ERC20SwapModule();
        address sender = address(this);
        uint256 amountIn = 1 ether;
        uint256 minAmountOut = (amountIn * 85) / 100;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: Constants.STETH,
                tokenOut: Constants.WSTETH,
                amountIn: amountIn,
                minAmountOut: minAmountOut,
                deadline: type(uint256).max
            }),
            Constants.WSTETH,
            abi.encodeWithSelector(IWSteth.wrap.selector, amountIn)
        );

        deal(Constants.WSTETH, sender, amountIn);
        IWSteth(Constants.WSTETH).unwrap(amountIn);

        {
            uint256 balanceBefore = IERC20(Constants.WSTETH).balanceOf(sender);
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            assertTrue(success);
            response = abi.decode(response, (bytes));
            uint256 addedValue = abi.decode(response, (uint256));
            uint256 balanceAfter = IERC20(Constants.WSTETH).balanceOf(sender);
            assertEq(balanceBefore + addedValue, balanceAfter);
            assertTrue(addedValue >= minAmountOut);
        }
    }

    function testSwapWstethToSteth() external {
        ERC20SwapModule module = new ERC20SwapModule();
        address sender = address(this);
        uint256 amountIn = 1 ether;
        uint256 minAmountOut = (amountIn * 100) / 86;

        bytes memory delegateCallData = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: Constants.WSTETH,
                tokenOut: Constants.STETH,
                amountIn: amountIn,
                minAmountOut: minAmountOut,
                deadline: type(uint256).max
            }),
            Constants.WSTETH,
            abi.encodeWithSelector(IWSteth.unwrap.selector, amountIn)
        );

        deal(Constants.WSTETH, sender, amountIn);

        {
            uint256 balanceBefore = IERC20(Constants.STETH).balanceOf(sender);
            (bool success, bytes memory response) = address(module)
                .delegatecall(delegateCallData);
            assertTrue(success);
            response = abi.decode(response, (bytes));
            uint256 addedValue = abi.decode(response, (uint256));
            uint256 balanceAfter = IERC20(Constants.STETH).balanceOf(sender);

            uint256 actualAddedValue = balanceAfter - balanceBefore;
            assertEq(
                addedValue,
                actualAddedValue + 1 wei /* roundings in STETH contract */
            );
            assertTrue(addedValue >= minAmountOut);
        }
    }
}
