// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface ITvlModule {
    struct Data {
        address token;
        address underlyingToken;
        uint256 amount;
        uint256 underlyingAmount;
        bool isDebt;
    }

    function tvl(
        address user,
        bytes memory params
    ) external view returns (Data[] memory data);
}
