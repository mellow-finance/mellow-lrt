// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IRatiosOracle.sol";
import "../IVault.sol";

import "../utils/IDefaultAccessControl.sol";

interface IManagedRatiosOracle is IRatiosOracle {
    error InvalidToken();
    error InvalidDataLength();
    error Forbidden();
    error InvalidCumulativeRatio();

    struct Data {
        address[] tokens;
        uint256[] ratiosX96;
    }

    function Q96() external view returns (uint256);

    function updateRatios(address vault, Data memory data) external;

    function vaultToData(address vault) external view returns (bytes memory);
}
