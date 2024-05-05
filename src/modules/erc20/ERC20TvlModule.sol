// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/erc20/IERC20TvlModule.sol";
import "../DefaultModule.sol";

contract ERC20TvlModule is IERC20TvlModule, DefaultModule {
    /// @inheritdoc ITvlModule
    function tvl(
        address vault
    ) external view noDelegateCall returns (Data[] memory data) {
        address[] memory tokens = IVault(vault).underlyingTokens();
        data = new Data[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            data[i].token = tokens[i];
            data[i].underlyingToken = tokens[i];
            data[i].amount = IERC20(tokens[i]).balanceOf(vault);
            data[i].underlyingAmount = data[i].amount;
        }
    }
}
