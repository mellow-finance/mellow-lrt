// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "./IValidator.sol";

/**
 * @title ManagedValidator
 * @notice A role-based validator that provides control over access permissions.
 *         Allows role-based management of contract permissions and supports custom validation logic.
 *
 *         The primary validator contract of the system, used to check the access permissions of users to call contracts with specified selectors.
 *         The main function of the contract is hasPermissions(from, to, selector), which checks whether the specified caller "from" has the right to make the call to.call(abi.encodeWithSelector(selector, someData)).
 *
 *         Bitwise masks are used to store roles, thus the maximum number of roles in the system is limited to 256 (0-255).
 *         The system consists of 4 types of roles:
 *             1. publicRoles - bitmask of public roles available to all users
 *             2. userRoles - bitmask of roles for the calling user
 *             3. allowAllSignaturesRoles - bitmask of roles for the called contract
 *             4. allowSignatureRoles - bitmask of roles for the called contract and specific selector
 *
 *         Additionally, the system has a dedicated role - 255 - ADMIN_ROLE, which grants full access to all contract functions without additional checks.
 *
 *         Therefore, the hasPermissions algorithm looks like this:
 *             1. Determine the set of roles possessed by the specified user (userRoles[from] | publicRoles)
 *             2. If the user has the ADMIN_ROLE role, access is granted ((userRoles[from] | publicRoles) & ADMIN_ROLE_MASK != 0)
 *             3. If the called contract has at least one role in its corresponding set that matches a role in the user's role set, access is granted (allowAllSignaturesRoles[to] & (publicRoles | userRoles[from]) != 0)
 *             4. If the called contract with specified function selector have at least one role in their corresponding role sets that matches a role in the user's role set, access is granted (allowSignatureRoles[to][selector] & (publicRoles | userRoles[from]) != 0)
 *             5. Otherwise, access is denied and the function returns false
 *
 *         For greater flexibility, it is possible to set a custom validator for the called contract, which will be used after the standard check of permissions.
 *         Thus, the validate function checks the presence of permissions as follows:
 *             1. If the data does not contain at least 4 bytes (required for the selector), the function reverts with an InvalidData error.
 *             2. If the hasPermissions function returns false, the function reverts with a Forbidden error.
 *             3. If a custom validator is set for the contract, the validate function of the custom validator is called.
 */
interface IManagedValidator is IValidator {
    /// @dev Errors
    error Forbidden();
    error InvalidData();

    /**
     * @notice Storage structure used for maintaining role-based access control data.
     */
    struct Storage {
        /// @dev Maps each user's address to their assigned roles using a bitmask.
        mapping(address => uint256) userRoles;
        /// @dev A bitmask representing public roles that are accessible by all users.
        uint256 publicRoles;
        /// @dev Maps each contract's address to a bitmask of roles that allow access to all functions on the contract.
        mapping(address => uint256) allowAllSignaturesRoles;
        /// @dev Maps each contract's address and function signature to a bitmask of roles that allow access to specific functions.
        mapping(address => mapping(bytes4 => uint256)) allowSignatureRoles;
        /// @dev Maps each contract's address to the address of a custom validator, if one is set.
        mapping(address => address) customValidator;
    }

    /// @dev A constant representing the admin role bitmask.
    function ADMIN_ROLE_MASK() external view returns (uint256);

    /// @dev A constant representing the storage position for the role-based data.
    function STORAGE_POSITION() external view returns (bytes32);

    /**
     * @notice Checks whether a user has permission for a specific function on a given contract.
     * @param user The address of the user to check.
     * @param contractAddress The address of the contract being accessed.
     * @param signature The function signature being checked.
     * @return `true` if the user has permission, otherwise `false`.
     */
    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) external view returns (bool);

    /**
     * @notice Ensures that a user has the necessary permissions for the specified function.
     * @param user The address of the user being verified.
     * @param contractAddress The address of the contract being accessed.
     * @param signature The function signature being checked.
     * @dev Reverts with `Forbidden` if the user lacks the required permissions.
     */
    function requirePermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) external view;

    /**
     * @notice Grants a public role.
     * @param role The bitmask index of the role to grant.
     */
    function grantPublicRole(uint8 role) external;

    /**
     * @notice Revokes a public role, preventing all users from accessing the specified functions.
     * @param role The bitmask index of the role to revoke.
     */
    function revokePublicRole(uint8 role) external;

    /**
     * @notice Assigns a specific role to a given user.
     * @param user The address of the user to assign the role to.
     * @param role The bitmask index of the role to assign.
     */
    function grantRole(address user, uint8 role) external;

    /**
     * @notice Revokes a specific role from a given user.
     * @param user The address of the user to revoke the role from.
     * @param role The bitmask index of the role to revoke.
     */
    function revokeRole(address user, uint8 role) external;

    /**
     * @notice Sets a custom validator for a specified contract.
     * @param contractAddress The address of the contract that will use the custom validator.
     * @param validator The address of the custom validator.
     * @dev Reverts with `Forbidden` if the validator is set to this contract.
     */
    function setCustomValidator(
        address contractAddress,
        address validator
    ) external;

    /**
     * @notice Grants a role for a specified contract.
     * @param contractAddress The address of the contract.
     * @param role The bitmask index of the role to grant.
     */
    function grantContractRole(address contractAddress, uint8 role) external;

    /**
     * @notice Revokes a role from a specified contract.
     * @param contractAddress The address of the contract.
     * @param role The bitmask index of the role to revoke.
     */
    function revokeContractRole(address contractAddress, uint8 role) external;

    /**
     * @notice Grants a role for a specified pair contract-selector.
     * @param contractAddress The address of the contract.
     * @param signature The function signature.
     * @param role The bitmask index of the role to grant.
     */
    function grantContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external;

    /**
     * @notice Revokes a role from a specified pair contract-selector.
     * @param contractAddress The address of the contract.
     * @param signature The function signature.
     * @param role The bitmask index of the role to revoke.
     */
    function revokeContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external;

    /**
     * @notice Returns the custom validator assigned to a specified contract.
     * @param contractAddress The address of the contract.
     * @return address of the custom validator.
     */
    function customValidator(
        address contractAddress
    ) external view returns (address);

    /**
     * @notice Returns the bitmask representing the roles assigned to a given user.
     * @param user The address of the user.
     * @return uint256 The bitmask of roles assigned to the user.
     */
    function userRoles(address user) external view returns (uint256);

    /**
     * @notice Returns the bitmask representing the public roles accessible to all users.
     * @return uint256 The bitmask of public roles.
     */
    function publicRoles() external view returns (uint256);

    /**
     * @notice Returns the bitmask representing roles that allow access to all functions on a specific contract.
     * @param contractAddress The address of the contract.
     * @return uint256 The bitmask of roles allowing access to all functions on the contract.
     */
    function allowAllSignaturesRoles(
        address contractAddress
    ) external view returns (uint256);

    /**
     * @notice Returns the bitmask representing roles that allow access to specific pair of contract-selector.
     * @param contractAddress The address of the contract.
     * @param selector The function signature.
     * @return The bitmask of roles allowing access to the specified function on the contract.
     */
    function allowSignatureRoles(
        address contractAddress,
        bytes4 selector
    ) external view returns (uint256);

    /**
     * @notice Validates access permissions for a user to execute a function on a target contract.
     * @param from The address of the user attempting the action.
     * @param to The address of the target contract.
     * @param data The call data containing the function signature and arguments.
     * @dev Reverts with `InvalidData` if the call data is too short.
     *      Uses a custom validator if one is configured for the target contract.
     */
    function validate(
        address from,
        address to,
        bytes calldata data
    ) external view;

    /**
     * @notice Emitted when a public role is granted to a user in the Managed Validator contract.
     * @param role The index of the public role.
     */
    event PublicRoleGranted(uint8 role);

    /**
     * @notice Emitted when a public role is revoked from a user in the Managed Validator contract.
     * @param role The index of the public role.
     */
    event PublicRoleRevoked(uint8 role);

    /**
     * @notice Emitted when a role is granted to a user in the Managed Validator contract.
     * @param user The address of the user.
     * @param role The index of the role.
     */
    event RoleGranted(address indexed user, uint8 role);

    /**
     * @notice Emitted when a role is revoked from a user in the Managed Validator contract.
     * @param user The address of the user.
     * @param role The index of the role.
     */
    event RoleRevoked(address indexed user, uint8 role);

    /**
     * @notice Emitted when a custom validator is set for a contract in the Managed Validator contract.
     * @param contractAddress The address of the contract.
     * @param validator The address of the custom validator.
     */
    event CustomValidatorSet(
        address indexed contractAddress,
        address validator
    );

    /**
     * @notice Emitted when a role is granted to a contract in the Managed Validator contract.
     * @param contractAddress The address of the contract.
     * @param role The index of the role.
     */
    event ContractRoleGranted(address indexed contractAddress, uint8 role);

    /**
     * @notice Emitted when a role is revoked from a contract in the Managed Validator contract.
     * @param contractAddress The address of the contract.
     * @param role The index of the role.
     */
    event ContractRoleRevoked(address indexed contractAddress, uint8 role);

    /**
     * @notice Emitted when a role is granted to a pair contract-selector in the Managed Validator contract.
     * @param contractAddress The address of the contract.
     * @param signature The function signature.
     * @param role The index of the role.
     */
    event ContractSignatureRoleGranted(
        address indexed contractAddress,
        bytes4 signature,
        uint8 role
    );

    /**
     * @notice Emitted when a role is revoked from a pair contract-selector in the Managed Validator contract.
     * @param contractAddress The address of the contract.
     * @param signature The function signature.
     * @param role The index of the role.
     */
    event ContractSignatureRoleRevoked(
        address indexed contractAddress,
        bytes4 signature,
        uint8 role
    );
}
