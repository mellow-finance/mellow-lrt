// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/modules/IDefaultModule.sol";

abstract contract DefaultModule is IDefaultModule {
    address private immutable _this = address(this);

    modifier onlyDelegateCall() {
        if (address(this) == _this) revert Forbidden();
        _;
    }

    modifier noDelegateCall() {
        if (address(this) != _this) revert Forbidden();
        _;
    }
}
