// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDefaultCollateralFactory  {
    function create(address asset, uint256 initialLimit, address limitIncreaser) external returns (address);
}