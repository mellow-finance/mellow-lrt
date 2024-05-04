// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        assertNotEq(address(validator), address(0));
        validator.requireAdmin(admin);
    }

    function testValidateFailsWithInvalidLength() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        bytes memory data = new bytes(0x123);
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        validator.validate(address(0), address(0), data);
    }

    function testValidateFailsWithInvalidSelector() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        bytes memory data = new bytes(0x124);
        vm.expectRevert(abi.encodeWithSignature("InvalidSelector()"));
        validator.validate(address(0), address(0), data);
    }

    function testValidateFailsWithUnsupportedRouter() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);

        address unsupportedRouter = address(1);
        bytes memory data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: address(0),
                tokenOut: address(0),
                amountIn: 0,
                minAmountOut: 0,
                deadline: 0
            }),
            unsupportedRouter
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        validator.validate(address(0), address(0), data);

        data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: address(0),
                tokenOut: address(0),
                amountIn: 0,
                minAmountOut: 0,
                deadline: 0
            }),
            unsupportedRouter,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("UnsupportedRouter()"));
        validator.validate(address(0), address(0), data);
    }

    function testValidateFailsWithUnsupportedToken() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);

        address router = address(1);
        vm.prank(admin);
        validator.setSupportedRouter(router, true);

        bytes memory data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: address(0),
                tokenOut: address(0),
                amountIn: 0,
                minAmountOut: 0,
                deadline: 0
            }),
            router,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("UnsupportedToken()"));
        validator.validate(address(0), address(0), data);

        address tokenIn = address(2);
        vm.prank(admin);
        validator.setSupportedToken(tokenIn, true);

        data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: tokenIn,
                tokenOut: address(0),
                amountIn: 0,
                minAmountOut: 0,
                deadline: 0
            }),
            router,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("UnsupportedToken()"));
        validator.validate(address(0), address(0), data);
    }

    function testValidateFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);

        address router = address(1);
        address tokenIn = address(2);
        address tokenOut = address(3);
        vm.startPrank(admin);
        validator.setSupportedRouter(router, true);
        validator.setSupportedToken(tokenIn, true);
        validator.setSupportedToken(tokenOut, true);
        vm.stopPrank();

        bytes memory data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: tokenIn,
                tokenOut: tokenIn,
                amountIn: 1,
                minAmountOut: 1,
                deadline: block.timestamp + 1
            }),
            router,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.validate(address(0), address(0), data);

        data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: 0,
                minAmountOut: 1,
                deadline: block.timestamp + 1
            }),
            router,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.validate(address(0), address(0), data);

        data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: 1,
                minAmountOut: 0,
                deadline: block.timestamp + 1
            }),
            router,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.validate(address(0), address(0), data);

        data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: 1,
                minAmountOut: 1,
                deadline: block.timestamp - 1
            }),
            router,
            new bytes(4)
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.validate(address(0), address(0), data);
    }

    function testValidate() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);

        address router = address(1);
        address tokenIn = address(2);
        address tokenOut = address(3);
        vm.startPrank(admin);
        validator.setSupportedRouter(router, true);
        validator.setSupportedToken(tokenIn, true);
        validator.setSupportedToken(tokenOut, true);
        vm.stopPrank();

        bytes memory data = abi.encodeWithSelector(
            IERC20SwapModule.swap.selector,
            IERC20SwapModule.SwapParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountIn: 1,
                minAmountOut: 1,
                deadline: block.timestamp
            }),
            router,
            new bytes(5)
        );
        validator.validate(address(0), address(0), data);
    }

    function testSetSupportedToken() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        address token = address(1);
        assertFalse(validator.isSupportedToken(token));
        vm.prank(admin);
        validator.setSupportedToken(token, true);
        assertTrue(validator.isSupportedToken(token));
        vm.prank(admin);
        validator.setSupportedToken(token, false);
        assertFalse(validator.isSupportedToken(token));
    }

    function testSetSupportedTokenFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        address token = address(1);
        assertFalse(validator.isSupportedToken(token));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setSupportedToken(token, true);
    }

    function testSetSupportedRouter() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        address router = address(1);
        assertFalse(validator.isSupportedRouter(router));
        vm.prank(admin);
        validator.setSupportedRouter(router, true);
        assertTrue(validator.isSupportedRouter(router));
        vm.prank(admin);
        validator.setSupportedRouter(router, false);
        assertFalse(validator.isSupportedRouter(router));
    }

    function testSetSupportedRouterFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("validator-admin")));
        ERC20SwapValidator validator = new ERC20SwapValidator(admin);
        address router = address(1);
        assertFalse(validator.isSupportedRouter(router));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        validator.setSupportedRouter(router, true);
    }
}
