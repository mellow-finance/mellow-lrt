// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../interfaces/modules/erc20/IManagedTvlModule.sol";
import "../DefaultModule.sol";

contract ManagedTvlModule is IManagedTvlModule, DefaultModule {
    /// @inheritdoc IManagedTvlModule
    mapping(address => bytes) public vaultParams;

    /// @inheritdoc IManagedTvlModule
    function setParams(
        address vault,
        Data[] memory data
    ) external noDelegateCall {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        for (uint256 i = 0; i < data.length; i++)
            if (!IVault(vault).isUnderlyingToken(data[i].underlyingToken))
                revert InvalidToken();
        vaultParams[vault] = abi.encode(data);
        emit ManagedTvlModuleSetParams(vault, data, block.timestamp);
    }

    /// @inheritdoc ITvlModule
    function tvl(
        address vault
    ) external view noDelegateCall returns (Data[] memory data) {
        bytes memory data_ = vaultParams[vault];
        if (data_.length == 0) return data;
        data = abi.decode(data_, (Data[]));
    }
}
