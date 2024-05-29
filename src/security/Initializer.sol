// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../Vault.sol";

contract Initializer is ERC20, DefaultAccessControl, ReentrancyGuard {
    VaultConfigurator public configurator;

    constructor()
        ERC20("Initializer", "init")
        DefaultAccessControl(address(this))
    {}

    function initialize(
        string memory name_,
        string memory symbol_,
        address admin_
    ) external {
        if (address(configurator) != address(0)) revert();
        configurator = new VaultConfigurator();

        // copy and paste from DefaultAccessControl constructor
        if (admin_ == address(0)) revert AddressZero();
        _grantRole(OPERATOR, admin_);
        _grantRole(ADMIN_ROLE, admin_);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_DELEGATE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(OPERATOR, ADMIN_DELEGATE_ROLE);

        // we want to only allow strings strictly less than 32 bytes in length to store them in 1 slot
        if (bytes(name_).length >= 0x20) revert("Too long name");
        if (bytes(symbol_).length >= 0x20) revert("Too long symbol");
        // update slots 3 and 4, which store the _name string and the _symbol string
        assembly {
            sstore(3, or(mload(add(name_, 0x20)), shl(1, mload(name_))))
            sstore(4, or(mload(add(symbol_, 0x20)), shl(1, mload(symbol_))))
        }
    }
}
