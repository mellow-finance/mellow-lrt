// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultProxyImplementation is ERC20 {
    error Locked();

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function _update(address, address, uint256) internal pure override {
        revert Locked();
    }
}
