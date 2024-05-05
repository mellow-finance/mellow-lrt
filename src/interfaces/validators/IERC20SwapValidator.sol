// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IValidator.sol";

import "../modules/erc20/IERC20SwapModule.sol";

interface IERC20SwapValidator is IValidator {
    error InvalidLength();
    error InvalidSelector();
    error UnsupportedToken();
    error UnsupportedRouter();

    function isSupportedRouter(address) external view returns (bool);

    function isSupportedToken(address) external view returns (bool);

    function setSupportedRouter(address router, bool flag) external;

    function setSupportedToken(address token, bool flag) external;

    function validate(address, address, bytes calldata data) external view;
}
