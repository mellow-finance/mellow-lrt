// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface IValidator {
    function validate(address to, bytes memory data) external;
}
