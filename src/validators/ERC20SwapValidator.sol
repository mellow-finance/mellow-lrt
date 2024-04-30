// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/validators/IValidator.sol";
import "../utils/DefaultAccessControl.sol";

import "../modules/erc20/ERC20SwapModule.sol";

contract ERC20SwapValidator is IValidator, DefaultAccessControl {
    constructor(address admin) DefaultAccessControl(admin) {}

    mapping(address => bool) public isSupportedRouter;
    mapping(address => bool) public isSupportedToken;

    function setSupportedRouter(address router, bool flag) external {
        _requireAdmin();
        isSupportedRouter[router] = flag;
    }

    function setSupportedToken(address router, bool flag) external {
        _requireAdmin();
        isSupportedToken[router] = flag;
    }

    function validate(address, address, bytes calldata data) external view {
        if (data.length < 0x104)
            revert("ERC20SwapValidator: invalid data length.");
        bytes4 selector = bytes4(data[:4]);
        if (ERC20SwapModule.swap.selector != selector) revert Forbidden();
        (
            ERC20SwapModule.SwapParams memory params,
            address to,
            bytes memory swapData
        ) = abi.decode(data[4:], (ERC20SwapModule.SwapParams, address, bytes));
        if (
            !isSupportedRouter[to] ||
            !isSupportedToken[params.tokenIn] ||
            !isSupportedToken[params.tokenOut] ||
            params.tokenIn == params.tokenOut ||
            params.amountIn == 0 ||
            params.minAmountOut == 0
        ) revert Forbidden();
    }
}
