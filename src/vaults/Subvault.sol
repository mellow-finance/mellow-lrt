// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/vaults/ISubvault.sol";

abstract contract Subvault is ISubvault {
    IRootVault public immutable rootVault;

    constructor(IRootVault rootVault_) {
        rootVault = rootVault_;
    }

    modifier onlyRootVault() {
        if (msg.sender != address(rootVault)) revert NotAuthorized();
        _;
    }

    modifier onlyOperator() {
        if (!IDefaultAccessControl(address(rootVault)).isOperator(msg.sender))
            revert NotAuthorized();
        _;
    }

    modifier onlyAdmin() {
        if (!IDefaultAccessControl(address(rootVault)).isAdmin(msg.sender))
            revert NotAuthorized();
        _;
    }

    modifier atLeastOperator() {
        if (
            !IDefaultAccessControl(address(rootVault)).isOperator(msg.sender) &&
            !IDefaultAccessControl(address(rootVault)).isAdmin(msg.sender)
        ) revert NotAuthorized();
        _;
    }

    modifier atLeastOperatorOrRootVault() {
        if (
            !IDefaultAccessControl(address(rootVault)).isOperator(msg.sender) &&
            !IDefaultAccessControl(address(rootVault)).isAdmin(msg.sender) &&
            msg.sender != address(rootVault)
        ) revert NotAuthorized();
        _;
    }

    function externalCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external atLeastOperator returns (bool success, bytes memory response) {
        rootVault.validator().validate(address(this), to, selector, data);
        (success, response) = to.call(data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(ISubvault).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
