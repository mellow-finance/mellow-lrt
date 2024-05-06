// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../external/symbiotic/IBond.sol";
import "../../utils/IDefaultAccessControl.sol";

import "../ITvlModule.sol";

interface IDefaultBondTvlModule is ITvlModule {
    function vaultParams(address vault) external view returns (bytes memory);

    function setParams(address vault, address[] memory bonds) external;
}
