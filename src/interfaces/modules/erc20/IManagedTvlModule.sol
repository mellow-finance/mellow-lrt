// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../ITvlModule.sol";
import "../../utils/IDefaultAccessControl.sol";

interface IManagedTvlModule is ITvlModule {
    function vaultParams(address) external view returns (bytes memory);

    function setParams(address vault, Data[] memory data) external;
}
