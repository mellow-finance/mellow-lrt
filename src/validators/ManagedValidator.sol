// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/validators/IManagedValidator.sol";

import "../utils/DefaultAccessControl.sol";

contract ManagedValidator is IManagedValidator {
    /// @inheritdoc IManagedValidator
    uint256 public constant ADMIN_ROLE_MASK = 1 << 255;
    /// @inheritdoc IManagedValidator
    bytes32 public constant STORAGE_POSITION =
        keccak256("mellow.lrt.permissions.storage");

    modifier authorized() {
        requirePermission(msg.sender, address(this), msg.sig);
        _;
    }

    constructor(address admin) {
        Storage storage ds = _storage();
        ds.userRoles[admin] = ADMIN_ROLE_MASK;
    }

    function _storage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    /// @inheritdoc IManagedValidator
    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) public view returns (bool) {
        Storage storage s = _storage();
        uint256 roleSet = s.userRoles[user] | s.publicRoles;
        if ((roleSet & ADMIN_ROLE_MASK) > 0) return true;
        if ((roleSet & s.allowAllSignaturesRoles[contractAddress]) > 0)
            return true;
        if ((roleSet & s.allowSignatureRoles[contractAddress][signature]) > 0)
            return true;
        return false;
    }

    /// @inheritdoc IManagedValidator
    function requirePermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) public view {
        if (!hasPermission(user, contractAddress, signature))
            revert Forbidden();
    }

    /// @inheritdoc IManagedValidator
    function grantPublicRole(uint8 role) external authorized {
        _storage().publicRoles |= 1 << role;
        emit PublicRoleGranted(role);
    }

    /// @inheritdoc IManagedValidator
    function revokePublicRole(uint8 role) external authorized {
        _storage().publicRoles &= ~(1 << role);
        emit PublicRoleRevoked(role);
    }

    /// @inheritdoc IManagedValidator
    function grantRole(address user, uint8 role) external authorized {
        _storage().userRoles[user] |= 1 << role;
        emit RoleGranted(user, role);
    }

    /// @inheritdoc IManagedValidator
    function revokeRole(address user, uint8 role) external authorized {
        _storage().userRoles[user] &= ~(1 << role);
        emit RoleRevoked(user, role);
    }

    /// @inheritdoc IManagedValidator
    function setCustomValidator(
        address contractAddress,
        address validator
    ) external authorized {
        if (validator == address(this)) revert Forbidden();
        _storage().customValidator[contractAddress] = validator;
        emit CustomValidatorSet(contractAddress, validator);
    }

    /// @inheritdoc IManagedValidator
    function grantContractRole(
        address contractAddress,
        uint8 role
    ) external authorized {
        _storage().allowAllSignaturesRoles[contractAddress] |= 1 << role;
        emit ContractRoleGranted(contractAddress, role);
    }

    /// @inheritdoc IManagedValidator
    function revokeContractRole(
        address contractAddress,
        uint8 role
    ) external authorized {
        _storage().allowAllSignaturesRoles[contractAddress] &= ~(1 << role);
        emit ContractRoleRevoked(contractAddress, role);
    }

    /// @inheritdoc IManagedValidator
    function grantContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external authorized {
        _storage().allowSignatureRoles[contractAddress][signature] |= 1 << role;
        emit ContractSignatureRoleGranted(contractAddress, signature, role);
    }

    /// @inheritdoc IManagedValidator
    function revokeContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external authorized {
        _storage().allowSignatureRoles[contractAddress][signature] &= ~(1 <<
            role);
        emit ContractSignatureRoleRevoked(contractAddress, signature, role);
    }

    /// @inheritdoc IManagedValidator
    function customValidator(
        address contractAddress
    ) external view returns (address) {
        return _storage().customValidator[contractAddress];
    }

    /// @inheritdoc IManagedValidator
    function userRoles(address user) external view returns (uint256) {
        return _storage().userRoles[user];
    }

    /// @inheritdoc IManagedValidator
    function publicRoles() external view returns (uint256) {
        return _storage().publicRoles;
    }

    /// @inheritdoc IManagedValidator
    function allowAllSignaturesRoles(
        address contractAddress
    ) external view returns (uint256) {
        return _storage().allowAllSignaturesRoles[contractAddress];
    }

    /// @inheritdoc IManagedValidator
    function allowSignatureRoles(
        address contractAddress,
        bytes4 selector
    ) external view returns (uint256) {
        return _storage().allowSignatureRoles[contractAddress][selector];
    }

    /// @inheritdoc IValidator
    function validate(
        address from,
        address to,
        bytes calldata data
    ) external view {
        if (data.length < 0x4) revert InvalidData();
        requirePermission(from, to, bytes4(data[:4]));
        address validator = _storage().customValidator[to];
        if (validator == address(0)) return;
        IValidator(validator).validate(from, to, data);
    }
}
