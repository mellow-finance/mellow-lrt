// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../external/symbiotic/IBond.sol";
import "../../IVault.sol";

import "../ITvlModule.sol";

interface IDefaultBondTvlModule is ITvlModule {
    struct Params {
        address[] bonds;
    }
}
