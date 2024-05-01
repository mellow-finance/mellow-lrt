// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/oracles/IManagedRatiosOracle.sol";

import "../libraries/external/FullMath.sol";

contract ManagedRatiosOracle is IManagedRatiosOracle {
    uint256 public constant Q96 = 2 ** 96;

    mapping(address => bytes) public vaultToData;

    function updateRatios(address vault, Data memory data) external override {
        if (!IDefaultAccessControl(vault).isAdmin(msg.sender))
            revert Forbidden();
        address[] memory tokens = IVault(vault).underlyingTokens();
        if (
            tokens.length != data.tokens.length ||
            data.tokens.length != data.ratiosX96.length
        ) revert InvalidLength();
        uint256 cumulativeRatioX96 = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != data.tokens[i]) revert InvalidToken();
            cumulativeRatioX96 += data.ratiosX96[i];
        }
        if (cumulativeRatioX96 != Q96) revert InvalidCumulativeRatio();
        vaultToData[vault] = abi.encode(data);
    }

    function getTargetRatiosX96(
        address vault
    ) external view override returns (uint128[] memory) {
        address[] memory tokens = IVault(vault).underlyingTokens();
        bytes memory data_ = vaultToData[vault];
        if (data_.length == 0) revert InvalidLength();
        Data memory data = abi.decode(data_, (Data));
        if (data.tokens.length != tokens.length) revert InvalidLength();
        for (uint256 i = 0; i < tokens.length; i++)
            if (data.tokens[i] != tokens[i]) revert InvalidToken();
        return data.ratiosX96;
    }
}
