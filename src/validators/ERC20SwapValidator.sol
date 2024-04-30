// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/validators/IValidator.sol";
import "../utils/DefaultAccessControl.sol";

import "../modules/erc20/ERC20SwapModule.sol";

contract ERC20SwapValidator is IValidator, DefaultAccessControl {
    constructor(address admin) DefaultAccessControl(admin) {}

    mapping(address => bool) public isSupportedRouter;

    function addSupported(address router) external {
        _requireAdmin();
        isSupportedRouter[router] = true;
    }

    function removeSupported(address router) external {
        _requireAdmin();
        isSupportedRouter[router] = false;
    }

    function validate(address, address, bytes calldata data) external view {
        if (data.length != 0x44)
            revert(
                string(
                    abi.encodePacked(
                        "ERC20SwapValidator: invalid length: ",
                        Strings.toString(data.length)
                    )
                )
            );
        bytes4 selector = bytes4(data[:4]);
        if (ERC20SwapModule.swap.selector != selector) revert Forbidden();

        (
            ERC20SwapModule.SwapParams memory params,
            address to,
            bytes memory swapData
        ) = abi.decode(data[4:], (ERC20SwapModule.SwapParams, address, bytes));

        if (!isSupportedRouter[to]) revert Forbidden();
        if (
            params.amountIn == 0 ||
            params.minAmountOut == 0 ||
            params.tokenIn == address(0) ||
            params.tokenOut == address(0)
        ) revert Forbidden();
        if (swapData.length < 0x4) revert Forbidden();
    }
}
