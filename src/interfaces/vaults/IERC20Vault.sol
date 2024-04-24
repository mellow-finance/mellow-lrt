// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./ISubvault.sol";

interface IERC20Vault is ISubvault {
    error InvalidLength();
    error InvalidSubvault();
    error InvalidAddress();
}
