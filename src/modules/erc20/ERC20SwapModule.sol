// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20SwapModule {
    using SafeERC20 for IERC20;

    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 deadline;
    }

    function swap(
        SwapParams calldata params,
        address to,
        bytes calldata data
    ) external returns (bytes memory) {
        if (params.deadline < block.timestamp)
            revert("ERC20SwapModule: deadline");
        uint256 tokenInBefore = IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutBefore = IERC20(params.tokenOut).balanceOf(
            address(this)
        );

        IERC20(params.tokenIn).safeIncreaseAllowance(to, params.amountIn);
        (bool success, bytes memory response) = to.call(data);
        if (!success) revert("ERC20SwapModule: swap failed");

        uint256 tokenInDelta = tokenInBefore -
            IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutDelta = IERC20(params.tokenOut).balanceOf(
            address(this)
        ) - tokenOutBefore;

        if (
            tokenInDelta > params.amountIn ||
            tokenOutDelta < params.minAmountOut
        ) revert("ERC20SwapModule: invalid swap");

        if (IERC20(params.tokenIn).allowance(address(this), to) != 0) {
            IERC20(params.tokenIn).forceApprove(to, 0);
        }

        return response;
    }
}
