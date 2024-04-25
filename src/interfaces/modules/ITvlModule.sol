// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface ITvlModule {
    function tvl(
        address user,
        bytes memory params
    ) external view returns (address[] memory tokens, uint256[] memory amounts);
}
