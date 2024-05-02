// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/symbiotic/IDefaultBondTvlModule.sol";

contract DefaultBondTvlModule is IDefaultBondTvlModule {
    function tvl(
        address vault,
        bytes memory params
    ) external view returns (Data[] memory data) {
        address[] memory bonds = abi.decode(params, (Params)).bonds;
        data = new Data[](bonds.length);
        for (uint256 i = 0; i < bonds.length; i++) {
            data[i].token = bonds[i];
            data[i].underlyingToken = IBond(bonds[i]).asset();
            if (IVault(vault).isUnderlyingToken(data[i].underlyingToken))
                revert InvalidToken();
            data[i].amount = IERC20(bonds[i]).balanceOf(vault);
            data[i].underlyingAmount = data[i].amount;
        }
    }
}
