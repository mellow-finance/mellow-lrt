// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../ITvlModule.sol";
import "../../utils/IDefaultAccessControl.sol";

import "../../IVault.sol";

// Interface declaration for a Managed Total Value Locked (TVL) Module
interface IManagedTvlModule is ITvlModule {
    error InvalidToken();

    /**
     * @notice Retrieves the parameters set for a specific vault.
     * @param vault The address of the vault for which to retrieve parameters.
     * @return Parameters set for the specified vault.
     * @dev This function returns the parameters set for the specified vault.
     *      It should not modify state variables and should be view-only.
     */
    function vaultParams(address vault) external view returns (bytes memory);

    /**
     * @notice Sets parameters for a specific vault.
     * @param vault The address of the vault for which to set parameters.
     * @param data An array of TVL data to be set as parameters for the vault.
     * @dev This function sets the parameters for the specified vault.
     *      It should only be callable by authorized contracts.
     */
    function setParams(address vault, Data[] memory data) external;

    /**
     * @notice Emitted when parameters are set for a specific vault.
     * @param vault The address of the vault for which parameters are set.
     * @param data An array of TVL data representing the parameters set for the vault.
     * @param timestamp Timestamp of the parameter setting.
     */
    event ManagedTvlModuleSetParams(
        address indexed vault,
        Data[] data,
        uint256 timestamp
    );
}
