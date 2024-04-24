// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IRatiosOracle {
    function getTargetRatiosX96(
        address rootVault
    ) external view returns (uint256[] memory ratiosX96);
}
