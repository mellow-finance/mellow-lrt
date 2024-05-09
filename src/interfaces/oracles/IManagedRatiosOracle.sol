// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IRatiosOracle.sol";
import "../IVault.sol";

import "../utils/IDefaultAccessControl.sol";

/**
 * @title IManagedRatiosOracle
 * @notice Interface defining a managed ratios oracle, enabling ratio updates and data retrieval.
 */
interface IManagedRatiosOracle is IRatiosOracle {
    /// @dev Errors
    error Forbidden();
    error InvalidCumulativeRatio();
    error InvalidLength();
    error InvalidToken();

    /**
     * @notice Structure representing the data for target ratios associated with a vault's tokens.
     * @param tokensHash The hash of the vault's tokens, used to validate the token data.
     * @param ratiosX96 An array representing the target ratios of each token using 96-bit precision.
     */
    struct Data {
        bytes32 tokensHash;
        uint128[] ratiosX96;
    }

    /**
     * @notice Returns the constant Q96 used for ratio calculations with 96-bit precision.
     * @return uint256 The value of Q96 (2^96) for ratio calculations.
     */
    function Q96() external view returns (uint256);

    /**
     * @notice Updates the target ratios for a specific vault.
     * @param vault The address of the vault to update the ratios for.
     * @param isDeposit A boolean indicating whether the ratios are for a deposit or a withdrawal.
     * @param ratiosX96 An array of target ratios for the vault's underlying tokens.
     * @dev The cumulative ratio must be exactly `Q96`.
     */
    function updateRatios(
        address vault,
        bool isDeposit,
        uint128[] memory ratiosX96
    ) external;

    /**
     * @notice Returns the encoded ratio data associated with a specific vault address.
     * @param vault The address of the vault to retrieve the data for.
     * @param isDeposit A boolean indicating whether the ratios are for a deposit or a withdrawal.
     * @return bytes The encoded ratio data.
     */
    function vaultToData(
        address vault,
        bool isDeposit
    ) external view returns (bytes memory);

    /**
     * @notice Emitted when ratios are updated for a specific vault in the Managed Ratios Oracle.
     * @param vault The address of the vault for which ratios are updated.
     * @param ratiosX96 An array of updated ratios expressed in 96-bit precision.
     * @param timestamp The timestamp when the ratios are updated.
     */
    event ManagedRatiosOracleUpdateRatios(
        address indexed vault,
        uint128[] ratiosX96,
        uint256 timestamp
    );
}
