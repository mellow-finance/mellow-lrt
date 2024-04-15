// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/ILrtService.sol";

contract SymbioticLrtService is ILrtService {
    function deposit(uint256 id, address token, uint256 amount) external {}

    function withdraw(uint256 id, address token, uint256 amount) external {}

    function compound(bytes memory params) external {}

    function getTokensAndAmounts(
        uint256 id
    ) external view returns (address[] memory, uint256[] memory) {}
}
