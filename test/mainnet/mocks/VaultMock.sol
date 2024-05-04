// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../src/utils/DefaultAccessControl.sol";

contract VaultMock is DefaultAccessControl, ERC20 {
    function testMock() public {}

    address[] private _underlyingTokens;
    uint256[] private _dust;
    uint256 public coefD9;

    constructor(
        address admin
    ) DefaultAccessControl(admin) ERC20("MockToken", "MOCK") {}

    function setDust(uint256[] memory dust_) external {
        _dust = dust_;
    }

    function setCoef(uint256 coefD9_) external {
        coefD9 = coefD9_;
    }

    function deposit(
        address to,
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256
    ) external returns (uint256[] memory, uint256) {
        _mint(to, (minLpAmount * coefD9) / 1e9);
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 dust = 0;
            if (_dust.length != 0) dust = _dust[i];
            IERC20(_underlyingTokens[i]).transferFrom(
                msg.sender,
                address(this),
                amounts[i] - dust
            );
        }
        return (new uint256[](0), 0);
    }

    function setUnderlyingTokens(address[] memory underlyingTokens_) external {
        _underlyingTokens = underlyingTokens_;
    }

    function underlyingTokens() external view returns (address[] memory) {
        return _underlyingTokens;
    }
}
