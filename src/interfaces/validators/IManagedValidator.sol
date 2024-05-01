// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./IValidator.sol";

interface IManagedValidator is IValidator {
    error Forbidden();

    struct Storage {
        mapping(address => uint256) userRoles;
        uint256 publicRoles;
        mapping(address => uint256) allowAllSignaturesRoles;
        mapping(address => mapping(bytes4 => uint256)) allowSignatureRoles;
        mapping(address => address) customValidator;
    }

    function ADMIN_ROLE_MASK() external view returns (uint256);
    function STORAGE_POSITION() external view returns (bytes32);
    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) external view returns (bool);

    function requirePermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) external view;

    function grantPublicRole(uint8 role) external;

    function revokePublicRole(uint8 role) external;

    function grantRole(address user, uint8 role) external;

    function revokeRole(address user, uint8 role) external;

    function setCustomValidator(
        address contractAddress,
        address validator
    ) external;

    function grantContractRole(address contractAddress, uint8 role) external;

    function revokeContractRole(address contractAddress, uint8 role) external;

    function grantContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external;

    function revokeContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external;

    function userRoles(address user) external view returns (uint256);

    function publicRoles() external view returns (uint256);

    function allowAllSignaturesRoles(
        address contractAddress
    ) external view returns (uint256);

    function allowSignatureRoles(
        address contractAddress,
        bytes4 selector
    ) external view returns (uint256);

    function validate(
        address from,
        address to,
        bytes calldata data
    ) external view;
}
