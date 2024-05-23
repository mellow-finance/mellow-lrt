// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/oracles/IManagedRatiosOracle.sol";

import "../libraries/external/FullMath.sol";

contract ManagedRatiosOracle is IManagedRatiosOracle {
    /// @inheritdoc IManagedRatiosOracle
    uint256 public constant Q96 = 2 ** 96;

    /// @inheritdoc IManagedRatiosOracle
    mapping(address => mapping(bool => bytes)) public vaultToData;

    /// @inheritdoc IManagedRatiosOracle
    function updateRatios(
        address vault,
        bool isDeposit,
        uint128[] memory ratiosX96
    ) external override {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        address[] memory tokens = IVault(vault).underlyingTokens();
        if (tokens.length != ratiosX96.length) revert InvalidLength();
        Data memory data = Data({
            tokensHash: keccak256(abi.encode(tokens)),
            ratiosX96: ratiosX96
        });
        uint256 total = 0;
        for (uint256 i = 0; i < tokens.length; i++) total += ratiosX96[i];
        if (total != Q96) revert InvalidCumulativeRatio();
        vaultToData[vault][isDeposit] = abi.encode(data);
        emit ManagedRatiosOracleUpdateRatios(vault, isDeposit, ratiosX96);
    }

    /// @inheritdoc IRatiosOracle
    function getTargetRatiosX96(
        address vault,
        bool isDeposit
    ) external view override returns (uint128[] memory) {
        bytes memory data_ = vaultToData[vault][isDeposit];
        if (data_.length == 0) revert InvalidLength();
        Data memory data = abi.decode(data_, (Data));
        address[] memory tokens = IVault(vault).underlyingTokens();
        if (data.tokensHash != keccak256(abi.encode(tokens)))
            revert InvalidToken();
        return data.ratiosX96;
    }
}
