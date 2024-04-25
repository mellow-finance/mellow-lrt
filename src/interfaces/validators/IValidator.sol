// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface IValidator {
    function validate(
        address from,
        address to,
        bytes4 selector,
        bytes memory data
    ) external view;
}
