// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/external/symbiotic/IBond.sol";

import "../../../interfaces/modules/ITvlModule.sol";

contract SymbioticBondTvlModule is ITvlModule {
    struct Params {
        address[] bonds;
    }

    function tvl(
        address user,
        bytes memory params
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        address[] memory bonds = abi.decode(params, (Params)).bonds;
        tokens = new address[](bonds.length);
        amounts = new uint256[](bonds.length);
        for (uint256 i = 0; i < bonds.length; i++) {
            amounts[i] = IERC20(bonds[i]).balanceOf(user);
            tokens[i] = IBond(bonds[i]).asset();
        }
    }
}
