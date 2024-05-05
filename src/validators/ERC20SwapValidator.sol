// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/validators/IERC20SwapValidator.sol";
import "../utils/DefaultAccessControl.sol";

contract ERC20SwapValidator is IERC20SwapValidator, DefaultAccessControl {
    constructor(address admin) DefaultAccessControl(admin) {}

    /// @inheritdoc IERC20SwapValidator
    mapping(address => bool) public isSupportedRouter;

    /// @inheritdoc IERC20SwapValidator
    mapping(address => bool) public isSupportedToken;

    /// @inheritdoc IERC20SwapValidator
    function setSupportedRouter(address router, bool flag) external {
        _requireAdmin();
        isSupportedRouter[router] = flag;
    }

    /// @inheritdoc IERC20SwapValidator
    function setSupportedToken(address token, bool flag) external {
        _requireAdmin();
        isSupportedToken[token] = flag;
    }

    /// @inheritdoc IValidator
    function validate(address, address, bytes calldata data) external view {
        if (data.length < 0x124) revert InvalidLength();
        bytes4 selector = bytes4(data[:4]);
        if (IERC20SwapModule.swap.selector != selector)
            revert InvalidSelector();
        (
            IERC20SwapModule.SwapParams memory params,
            address to,
            bytes memory swapData
        ) = abi.decode(data[4:], (IERC20SwapModule.SwapParams, address, bytes));
        if (!isSupportedRouter[to]) revert UnsupportedRouter();
        if (
            !isSupportedToken[params.tokenIn] ||
            !isSupportedToken[params.tokenOut]
        ) revert UnsupportedToken();
        if (
            params.tokenIn == params.tokenOut ||
            params.amountIn == 0 ||
            params.minAmountOut == 0 ||
            params.deadline < block.timestamp ||
            swapData.length <= 0x4
        ) revert Forbidden();
    }
}
