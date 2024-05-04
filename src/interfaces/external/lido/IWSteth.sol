// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWSteth {
    function wrap(uint256 stethAmount) external payable returns (uint256);

    function unwrap(uint256 wstethAmount) external returns (uint256);
}
