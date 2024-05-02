// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./IValidator.sol";

import "../modules/symbiotic/IDefaultBondModule.sol";

interface IDefaultBondValidator is IValidator {
    error InvalidLength();
    error ZeroAmount();
    error InvalidSelector();
    error UnsupportedBond();

    function isSupportedBond(address bond) external view returns (bool);

    function setSupportedBond(address bond, bool flag) external;
}
