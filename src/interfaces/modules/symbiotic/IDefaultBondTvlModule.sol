// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../external/symbiotic/IBond.sol";
import "../../utils/IDefaultAccessControl.sol";

import "../ITvlModule.sol";

import "../../IVault.sol";

// Interface declaration for Default Bond TVL Module
interface IDefaultBondTvlModule is ITvlModule {
    error InvalidToken();

    /**
     * @notice Retrieves the bond parameters set for a specific vault.
     * @param vault The address of the vault for which to retrieve bond parameters.
     * @return Bond parameters set for the specified vault.
     * @dev This function returns the bond parameters set for the specified vault.
     *      It should not modify state variables and should be view-only.
     */
    function vaultParams(address vault) external view returns (bytes memory);

    /**
     * @notice Sets bond parameters for a specific vault.
     * @param vault The address of the vault for which to set bond parameters.
     * @param bonds An array of bond addresses to be set as parameters for the vault.
     * @dev This function sets the bond parameters for the specified vault.
     *      It should only be callable by authorized contracts.
     */
    function setParams(address vault, address[] memory bonds) external;

    /**
     * @notice Emitted when parameters are set for a specific vault in the Default Bond TVL Module.
     * @param vault The address of the vault for which parameters are set.
     * @param bonds An array of bond addresses representing the parameters set for the vault.
     */
    event DefaultBondTvlModuleSetParams(address indexed vault, address[] bonds);
}
