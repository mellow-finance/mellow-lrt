// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./ISubvault.sol";

import "../external/symbiotic/IDefaultBond.sol";

interface IDefaultBondVault is ISubvault {
    error InvalidLength();
    error InvalidSubvault();
    error InvalidAddress();

    function bonds(address token) external view returns (address);

    function enableBond(address token, address bond) external;

    function disableBond(address token, address bond) external;
}
