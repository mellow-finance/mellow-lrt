// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/external/symbiotic/vault/IVault.sol";
import "../DefaultModule.sol";

contract SymbioticVaultModule is DefaultModule {
    using SafeERC20 for IERC20;

    function claimRewards()
        external
        onlyDelegateCall
        returns (uint256 shares)
    {}
}
