// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IDepositContract {
    function get_deposit_root() external view returns (bytes32 rootHash);
}
