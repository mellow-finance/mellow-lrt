// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../../interfaces/modules/ITvlModule.sol";
import "../../../interfaces/IVault.sol";

contract ERC20TvlModule is ITvlModule {
    function tvl(
        address vault,
        bytes memory
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        tokens = IVault(vault).underlyingTokens();
        amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            amounts[i] = IERC20(tokens[i]).balanceOf(vault);
        }
    }
}
