// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/modules/ITvlModule.sol";

contract ERC20TvlModule is ITvlModule {
    struct Params {
        address[] tokens;
    }

    function tvl(
        address user,
        bytes memory params
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = abi.decode(params, (Params)).tokens;
        amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            amounts[i] = IERC20(tokens[i]).balanceOf(user);
        }
    }
}
