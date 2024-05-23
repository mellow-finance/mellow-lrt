// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./IValidator.sol";

import "../modules/symbiotic/IDefaultBondModule.sol";

/**
 * @title IDefaultBondValidator
 * @notice Interface defining a validator for supported bond deposits and withdrawals.
 */
interface IDefaultBondValidator is IValidator {
    /// @dev Errors
    error InvalidLength(); // Thrown when data does not match the expected length.
    error ZeroAmount(); // Thrown when a transaction specifies a zero amount.
    error InvalidSelector(); // Thrown when a function selector is not recognized.
    error UnsupportedBond(); // Thrown when an unsupported bond is referenced.

    /**
     * @notice Checks if a specific bond is supported.
     * @param bond The address of the bond to verify.
     * @return `true` if the bond is supported, otherwise `false`.
     */
    function isSupportedBond(address bond) external view returns (bool);

    /**
     * @notice Sets the supported status of a specific bond.
     * @param bond The address of the bond to update.
     * @param flag `true` to mark the bond as supported, otherwise `false`.
     */
    function setSupportedBond(address bond, bool flag) external;

    /**
     * @notice Validates bond deposit or withdrawal operations, ensuring that only supported bonds are accessed.
     * @param data The calldata containing deposit or withdrawal details to validate.
     * @dev Reverts with appropriate errors if the data is incorrectly formatted or if the bond is unsupported.
     *      Checks for `deposit` or `withdraw` function signatures from the `IDefaultBondModule`.
     */
    function validate(
        address from,
        address to,
        bytes calldata data
    ) external view override;

    /**
     * @notice Emitted when a supported bond is set or updated in the Default Bond Validator contract.
     * @param bond The address of the bond.
     * @param flag A boolean indicating whether the bond is supported or not.
     * @param timestamp The timestamp when the action was executed.
     */
    event DefaultBondValidatorSetSupportedBond(
        address indexed bond,
        bool flag,
        uint256 timestamp
    );
}
