// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/oracles/IRatiosOracle.sol";
import "../interfaces/vaults/IRootVault.sol";

import "../utils/DefaultAccessControl.sol";

import "../libraries/external/FullMath.sol";

contract ManagedRatiosOracle is IRatiosOracle, DefaultAccessControl {
    uint256 public constant Q96 = 2 ** 96;

    mapping(address => mapping(address => uint256)) public vaultToTokenToWeight;

    constructor(address admin) DefaultAccessControl(admin) {}

    function updateRatios(
        address vault,
        address[] memory tokens,
        uint256[] memory weights
    ) external {
        _requireAdmin();
        for (uint256 i = 0; i < tokens.length; i++) {
            vaultToTokenToWeight[vault][tokens[i]] = weights[i];
        }
    }

    function getTargetRatiosX96(
        address rootVault
    ) external view returns (uint256[] memory ratiosX96) {
        address[] memory tokens = IRootVault(rootVault).tokens();
        uint256 cumulativeWeight = 0;
        uint256[] memory weights = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            weights[i] = vaultToTokenToWeight[rootVault][tokens[i]];
            cumulativeWeight += weights[i];
        }
        if (cumulativeWeight == 0) {
            revert("ManagedRatiosOracle: cumulative weight is 0");
        }

        ratiosX96 = new uint256[](tokens.length);
        uint256 index = 0;
        uint256 cumulativeRatios = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            ratiosX96[i] = FullMath.mulDiv(weights[i], Q96, cumulativeWeight);
            if (ratiosX96[i] > ratiosX96[index]) index = i;
            cumulativeRatios += ratiosX96[i];
        }
        if (cumulativeRatios != Q96) ratiosX96[index] += Q96 - cumulativeRatios;
    }
}
