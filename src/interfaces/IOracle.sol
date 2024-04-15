// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface IOracle {
    function getValue(
        address token,
        uint256 amount,
        address target
    ) external view returns (uint256);
}
