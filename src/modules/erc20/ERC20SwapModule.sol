// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/erc20/IERC20SwapModule.sol";
import "../DefaultModule.sol";

contract ERC20SwapModule is IERC20SwapModule, DefaultModule {
    using SafeERC20 for IERC20;

    function swap(
        SwapParams calldata params,
        address to,
        bytes calldata data
    ) external onlyDelegateCall returns (bytes memory) {
        if (params.deadline < block.timestamp) revert Deadline();
        uint256 tokenInBefore = IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutBefore = IERC20(params.tokenOut).balanceOf(
            address(this)
        );

        IERC20(params.tokenIn).safeIncreaseAllowance(to, params.amountIn);
        (bool success, bytes memory response) = to.call(data);
        if (!success) revert SwapFailed();

        uint256 tokenInDelta = tokenInBefore -
            IERC20(params.tokenIn).balanceOf(address(this));
        uint256 tokenOutDelta = IERC20(params.tokenOut).balanceOf(
            address(this)
        ) - tokenOutBefore;

        if (
            tokenInDelta > params.amountIn ||
            tokenOutDelta < params.minAmountOut
        ) revert InvalidSwapAmounts();

        if (IERC20(params.tokenIn).allowance(address(this), to) != 0) {
            IERC20(params.tokenIn).forceApprove(to, 0);
        }

        return response;
    }
}
