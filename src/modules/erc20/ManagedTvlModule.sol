// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/modules/ITvlModule.sol";

import "../../interfaces/utils/IDefaultAccessControl.sol";

contract ManagedTvlModule is ITvlModule {
    error Forbidden();

    mapping(address => bytes) public vaultTvls;

    function setVaultParameters(address vault, Data[] memory data) external {
        // TODO: fix permissions
        if (!IDefaultAccessControl(vault).isAdmin(msg.sender))
            revert Forbidden();
        vaultTvls[vault] = abi.encode(data);
    }

    function tvl(address vault) external view returns (Data[] memory data) {
        bytes memory data_ = vaultTvls[vault];
        if (data_.length == 0) return data;
        data = abi.decode(data_, (Data[]));
    }
}
