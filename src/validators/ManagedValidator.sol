// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/validators/IValidator.sol";

import "../utils/DefaultAccessControl.sol";

contract ManagedValidator is IValidator {
    error Forbidden();

    struct Storage {
        mapping(address => uint256) userRoles;
        uint256 publicRoles;
        mapping(address => uint256) allowAllSignaturesRoles;
        mapping(address => mapping(bytes4 => uint256)) allowSignatureRoles;
        mapping(address => address) customValidator;
    }

    uint256 public constant ADMIN_ROLE_MASK = 1 << 255;
    bytes32 public constant STORAGE_POSITION =
        keccak256("mellow.lrt.permissions.storage");

    modifier authorized() {
        requirePermission(msg.sender, address(this), msg.sig);
        _;
    }

    constructor(address admin) {
        Storage storage ds = _contractStorage();
        ds.userRoles[admin] = ADMIN_ROLE_MASK;
    }

    function _contractStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) public view returns (bool) {
        Storage storage ds = _contractStorage();
        uint256 roleSet = ds.userRoles[user] | ds.publicRoles;
        if ((roleSet & ADMIN_ROLE_MASK) > 0) return true;
        if ((roleSet & ds.allowAllSignaturesRoles[contractAddress]) > 0)
            return true;
        if ((roleSet & ds.allowSignatureRoles[contractAddress][signature]) > 0)
            return true;
        return false;
    }

    function requirePermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) public view {
        if (!hasPermission(user, contractAddress, signature)) {
            revert Forbidden();
        }
    }

    function grantPublicRole(uint8 role) external authorized {
        Storage storage ds = _contractStorage();
        ds.publicRoles |= 1 << role;
    }

    function revokePublicRole(uint8 role) external authorized {
        Storage storage ds = _contractStorage();
        ds.publicRoles &= ~(1 << role);
    }

    function grantRole(address user, uint8 role) external authorized {
        Storage storage ds = _contractStorage();
        ds.userRoles[user] |= 1 << role;
    }

    function revokeRole(address user, uint8 role) external authorized {
        Storage storage ds = _contractStorage();
        ds.userRoles[user] &= ~(1 << role);
    }

    function setCustomValidator(
        address contractAddress,
        address validator
    ) external authorized {
        Storage storage ds = _contractStorage();
        ds.customValidator[contractAddress] = validator;
    }

    function grantContractRole(
        address contractAddress,
        uint8 role
    ) external authorized {
        Storage storage ds = _contractStorage();
        ds.allowAllSignaturesRoles[contractAddress] |= 1 << role;
    }

    function revokeContractRole(
        address contractAddress,
        uint8 role
    ) external authorized {
        Storage storage ds = _contractStorage();
        ds.allowAllSignaturesRoles[contractAddress] &= ~(1 << role);
    }

    function grantContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external authorized {
        Storage storage ds = _contractStorage();
        ds.allowSignatureRoles[contractAddress][signature] |= 1 << role;
    }

    function revokeContractSignatureRole(
        address contractAddress,
        bytes4 signature,
        uint8 role
    ) external authorized {
        Storage storage ds = _contractStorage();
        ds.allowSignatureRoles[contractAddress][signature] &= ~(1 << role);
    }

    function userRoles(address user) external view returns (uint256) {
        return _contractStorage().userRoles[user];
    }

    function publicRoles() external view returns (uint256) {
        return _contractStorage().publicRoles;
    }

    function allowAllSignaturesRoles(
        address contractAddress
    ) external view returns (uint256) {
        return _contractStorage().allowAllSignaturesRoles[contractAddress];
    }

    function allowSignatureRoles(
        address contractAddress,
        bytes4 selector
    ) external view returns (uint256) {
        return
            _contractStorage().allowSignatureRoles[contractAddress][selector];
    }

    function validate(
        address from,
        address to,
        bytes calldata data
    ) external view {
        if (data.length < 4) revert("ManagedValidator: invalid data");
        requirePermission(from, to, bytes4(data[:4]));
        address validator = _contractStorage().customValidator[to];
        if (validator == address(0)) return;
        IValidator(validator).validate(from, to, data);
    }
}
