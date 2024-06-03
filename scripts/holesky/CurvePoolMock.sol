// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../src/utils/DefaultAccessControl.sol";

import "./IDefiCollector.sol";
import "./CurveCollector.sol";

contract CurvePoolMock is ICurvePool, ERC20 {
    address[] private _tokens;

    constructor(address[] memory tokens_) ERC20("", "") {
        _tokens = tokens_;
    }

    function coins(uint256 i) external view override returns (address) {
        return _tokens[i];
    }

    function N_COINS() external view returns (uint256) {
        return _tokens.length;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(to, amount);
    }

    function claim(address token, uint256 amount) external {
        IERC20(token).transfer(msg.sender, amount);
    }
}
