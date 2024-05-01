// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";

/// @notice This is a default access control with 3 roles:
///
/// - ADMIN: allowed to do anything
/// - ADMIN_DELEGATE: allowed to do anything except assigning ADMIN and ADMIN_DELEGATE roles
/// - OPERATOR: low-privileged role, generally keeper or some other bot
interface IDefaultAccessControl is IAccessControlEnumerable {
    error Forbidden();
    error AddressZero();

    function OPERATOR() external view returns (bytes32);

    function ADMIN_ROLE() external view returns (bytes32);

    function ADMIN_DELEGATE_ROLE() external view returns (bytes32);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is operator, `false` otherwise
    function isOperator(address who) external view returns (bool);
}
