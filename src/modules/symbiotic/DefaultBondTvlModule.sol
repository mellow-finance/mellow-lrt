// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/symbiotic/IDefaultBondTvlModule.sol";

contract DefaultBondTvlModule is IDefaultBondTvlModule {
    function tvl(
        address vault,
        bytes memory params
    )
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        address[] memory bonds = abi.decode(params, (Params)).bonds;
        tokens = IVault(vault).underlyingTokens();
        amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < bonds.length; i++) {
            address token = IBond(bonds[i]).asset();
            for (uint256 j = 0; j < tokens.length; j++) {
                if (token != tokens[j]) continue;
                amounts[j] += IBond(bonds[i]).balanceOf(vault);
                break;
            }
        }
    }
}
