// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/external/symbiotic/vault/IVault.sol";
import "../DefaultModule.sol";

import "./SymbioticVaultTvlModule.sol";

contract SymbioticVaultModule is DefaultModule {
    using SafeERC20 for IERC20;

    SymbioticVaultTvlModule public immutable symbioticVaultTvlModule;

    constructor(
        SymbioticVaultTvlModule symbioticVaultTvlModule_
    ) DefaultModule() {
        symbioticVaultTvlModule = symbioticVaultTvlModule_;
    }

    function allowAndDeposit(
        IVault vault,
        address onBehalfOf,
        uint256 amount
    ) external onlyDelegateCall returns (uint256 shares) {
        address collateral = vault.collateral();
        IERC20(collateral).safeIncreaseAllowance(address(vault), amount);
        shares = vault.deposit(onBehalfOf, amount);
    }

    function withdraw(
        IVault vault,
        address claimer,
        uint256 amount
    )
        external
        onlyDelegateCall
        returns (uint256 burnedShares, uint256 mintedShares)
    {
        (burnedShares, mintedShares) = vault.withdraw(claimer, amount);
        uint256 withdrawalEpoch = vault.currentEpoch() + 1;
        symbioticVaultTvlModule.addEpoch(address(vault), withdrawalEpoch);
    }

    function claim(
        IVault vault,
        address recipient,
        uint256 epoch
    ) external onlyDelegateCall returns (uint256 amount) {
        amount = vault.claim(recipient, epoch);
        symbioticVaultTvlModule.removeEpoch(address(vault), epoch);
    }

    function claimBatch(
        IVault vault,
        address recipient,
        uint256[] memory epochs
    ) external onlyDelegateCall returns (uint256 amount) {
        amount = vault.claimBatch(recipient, epochs);
        symbioticVaultTvlModule.removeEpochs(address(vault), epochs);
    }
}
