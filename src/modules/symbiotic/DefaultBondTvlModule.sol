// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/symbiotic/IDefaultBondTvlModule.sol";
import "../../interfaces/utils/IDefaultAccessControl.sol";

contract DefaultBondTvlModule is IDefaultBondTvlModule {
    error Forbidden();

    mapping(address => bytes) public vaultTvls;

    function setVaultParameters(
        address vault,
        address[] memory bonds
    ) external {
        // TODO: fix permissions
        if (!IDefaultAccessControl(vault).isAdmin(msg.sender))
            revert Forbidden();
        vaultTvls[vault] = abi.encode(bonds);
    }

    function tvl(address vault) external view returns (Data[] memory data) {
        bytes memory data_ = vaultTvls[vault];
        if (data_.length == 0) return data;
        address[] memory bonds = abi.decode(data_, (address[]));
        data = new Data[](bonds.length);
        for (uint256 i = 0; i < bonds.length; i++) {
            data[i].token = bonds[i];
            data[i].underlyingToken = IBond(bonds[i]).asset();
            data[i].amount = IERC20(bonds[i]).balanceOf(vault);
            data[i].underlyingAmount = data[i].amount;
        }
    }
}
