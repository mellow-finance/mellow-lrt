// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title IERC20SwapModule
 * @notice Interface defining methods for an ERC20 Swap Module.
 */
interface IERC20SwapModule {
    /// @dev Errors
    error Deadline();
    error SwapFailed();
    error InvalidSwapAmounts();

    /**
     * @notice Struct defining parameters for a token swap.
     */
    struct SwapParams {
        address tokenIn; // Address of the input token
        address tokenOut; // Address of the output token
        uint256 amountIn; // Amount of input token to swap
        uint256 minAmountOut; // Minimum amount of output token expected
        uint256 deadline; // Swap deadline timestamp
    }

    /**
     * @notice Executes a token swap.
     * @param params Parameters defining the swap.
     * @param to Address of the target contract to execute the swap on.
     * @param data Data to be passed to the target contract for the swap.
     * @return Result of the swap execution.
     */
    function swap(
        SwapParams calldata params,
        address to,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Emitted when a token swap occurs.
     * @param params Swap parameters including tokenIn, tokenOut, amountIn, minAmountOut, and deadline.
     * @param to The address receiving the swapped tokens.
     * @param data Additional data related to the swap.
     * @param timestamp Timestamp of the swap.
     * @param response Response data from the swap operation.
     */
    event ERC20SwapModuleSwap(
        SwapParams params,
        address to,
        bytes data,
        uint256 timestamp,
        bytes response
    );
}
