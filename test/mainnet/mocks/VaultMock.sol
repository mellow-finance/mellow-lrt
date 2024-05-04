// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../src/utils/DefaultAccessControl.sol";

contract VaultMock is DefaultAccessControl {
    constructor(address admin) DefaultAccessControl(admin) {}

    address[] private _underlyingTokens;

    function setUnderlyingTokens(address[] memory underlyingTokens_) external {
        _underlyingTokens = underlyingTokens_;
    }

    function underlyingTokens() external view returns (address[] memory) {
        return _underlyingTokens;
    }
}
