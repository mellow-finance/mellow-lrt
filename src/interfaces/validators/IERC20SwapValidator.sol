// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./IValidator.sol";

import "../modules/erc20/IERC20SwapModule.sol";

/**
 * @title IERC20SwapValidator
 * @notice Validator for ERC20 token swaps, ensuring that only authorized routers and tokens are used.
 */
interface IERC20SwapValidator is IValidator {
    /// @dev Errors
    error InvalidLength();
    error InvalidSelector();
    error UnsupportedToken();
    error UnsupportedRouter();

    /**
     * @dev Maps each router's address to a boolean indicating whether it is supported or not.
     * If `true`, the router is supported for swaps.
     */
    function isSupportedRouter(address) external view returns (bool);
    /**
     * @dev Maps each ERC20 token's address to a boolean indicating whether it is supported or not.
     * If `true`, the token is supported for swaps.
     */
    function isSupportedToken(address) external view returns (bool);

    /**
     * @notice Sets the supported status of a specific router.
     * @param router The address of the router to update.
     * @param flag `true` to mark the router as supported, otherwise `false`.
     */
    function setSupportedRouter(address router, bool flag) external;

    /**
     * @notice Sets the supported status of a specific ERC20 token.
     * @param token The address of the token to update.
     * @param flag `true` to mark the token as supported, otherwise `false`.
     */
    function setSupportedToken(address token, bool flag) external;

    /**
     * @notice Validates swap operations involving specific routers and tokens to ensure compliance.
     * @param from The address initiating the transaction.
     * @param to The address receiving the transaction (swap module).
     * @param data The calldata containing details of the swap operation.
     * @dev The `validate` function checks function signatures, swap parameters, and the validity of involved routers and tokens.
     *      Reverts with appropriate errors if validation fails.
     */
    function validate(
        address from,
        address to,
        bytes calldata data
    ) external view;

    /**
     * @notice Emitted when a supported router is set or updated in the ERC20 Swap Validator contract.
     * @param router The address of the router.
     * @param flag A boolean indicating whether the router is supported or not.
     * @param timestamp The timestamp when the action was executed.
     */
    event ERC20SwapValidatorSetSupportedRouter(
        address indexed router,
        bool flag,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a supported token is set or updated in the ERC20 Swap Validator contract.
     * @param token The address of the token.
     * @param flag A boolean indicating whether the token is supported or not.
     * @param timestamp The timestamp when the action was executed.
     */
    event ERC20SwapValidatorSetSupportedToken(
        address indexed token,
        bool flag,
        uint256 timestamp
    );
}
