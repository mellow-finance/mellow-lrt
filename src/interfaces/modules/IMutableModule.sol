// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface IMutableModule {
    function selectors() external view returns (bytes4[] memory selectors_);
}
