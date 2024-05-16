// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../ITvlModule.sol";
import "../../IVault.sol";

/**
 * @title IManagedTvlModule
 * @notice Interface defining methods for a managed Total Value Locked (TVL) Module,
 * allowing setting and retrieving parameters for specific vaults.
 */
interface IERC20TvlModule is ITvlModule {
    /**
     * @notice Calculates the Total Value Locked (TVL) of a vault holding ERC20 tokens.
     * @param vault The address of the vault for which to calculate the TVL.
     * @return data An array of TVL data for each underlying token held by the vault.
     * @dev The TVL data includes information such as token address, underlying token address,
     *      token balance, and underlying token balance.
     *      This function should be implemented to accurately calculate the TVL of the vault.
     *      It should not be callable via delegate calls.
     */
    function tvl(address vault) external view returns (Data[] memory data);
}
