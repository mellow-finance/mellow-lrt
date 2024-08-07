// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IVault as ISymbioticVault} from "../interfaces/external/symbiotic/vault/IVault.sol";
import {IVault} from "../interfaces/IVault.sol";

import {SymbioticStakerRewardsModule} from "../modules/symbiotic/SymbioticStakerRewardsModule.sol";
import {SymbioticVaultModule} from "../modules/symbiotic/SymbioticVaultModule.sol";
import {SymbioticVaultTvlModule} from "../modules/symbiotic/SymbioticVaultTvlModule.sol";

import {DefaultAccessControl} from "../utils/DefaultAccessControl.sol";

contract SymbioticVaultStrategy is DefaultAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Data {
        address stakerRewards;
        address farm;
    }

    SymbioticStakerRewardsModule public immutable rewardsModule;
    SymbioticVaultModule public immutable vaultModule;
    SymbioticVaultTvlModule public immutable tvlModule;

    IVault public immutable vault;

    mapping(address symbioticVault => EnumerableSet.UintSet)
        private _pendingWithdrawals;

    mapping(address rewardToken => Data) public farmToData;
    EnumerableSet.AddressSet private _approvedSymbioticVaults;

    constructor(
        address admin_,
        SymbioticStakerRewardsModule rewardsModule_,
        SymbioticVaultModule vaultModule_,
        SymbioticVaultTvlModule tvlModule_,
        IVault vault_
    ) DefaultAccessControl(admin_) {
        rewardsModule = rewardsModule_;
        vaultModule = vaultModule_;
        tvlModule = tvlModule_;
        vault = vault_;
    }

    function setFarmForRewardToken(
        address rewardToken,
        address stakerRewards,
        address farm
    ) external {
        _requireAdmin();
        // can be address(0) to remove the farm
        farmToData[rewardToken] = Data({
            stakerRewards: stakerRewards,
            farm: farm
        });
    }

    function setSymbioticVaultApproval(
        ISymbioticVault symbioticVault,
        bool approved
    ) external {
        _requireAdmin();
        if (approved) {
            _approvedSymbioticVaults.add(address(symbioticVault));
        } else {
            _approvedSymbioticVaults.remove(address(symbioticVault));
        }
    }

    // transfer of rewards from the stakerRewards contract to to the farm
    function transferRewards(
        address token,
        address network,
        uint256 maxRewards,
        bytes[] calldata hints
    ) external {
        _requireAtLeastOperator();
        Data memory farmData = farmToData[token];
        require(
            farmData.farm != address(0),
            "SymbioticVaultStrategy: farm not set"
        );
        rewardsModule.claimRewards(
            farmData.stakerRewards,
            farmData.farm,
            token,
            network,
            maxRewards,
            hints
        );
    }

    function transferRewards(address token, bytes calldata data) private {
        _requireAtLeastOperator();
        Data memory farmData = farmToData[token];
        require(
            farmData.farm != address(0),
            "SymbioticVaultStrategy: farm not set"
        );
        rewardsModule.claimRewards(
            farmData.stakerRewards,
            farmData.farm,
            token,
            data
        );
    }

    function requestWithdrawal(
        ISymbioticVault symbioticVault,
        uint256 amount
    ) external {
        _requireAtLeastOperator();
        require(
            _approvedSymbioticVaults.contains(address(symbioticVault)),
            "SymbioticVaultStrategy: vault not approved"
        );
        symbioticVault.withdraw(address(vault), amount);
        _pendingWithdrawals[address(symbioticVault)].add(
            symbioticVault.currentEpoch() + 1
        );
    }

    function claimWithdrawals(
        ISymbioticVault symbioticVault,
        uint256 maxEpochs
    ) external {
        _requireAtLeastOperator();
        require(
            _approvedSymbioticVaults.contains(address(symbioticVault)),
            "SymbioticVaultStrategy: vault not approved"
        );
        EnumerableSet.UintSet storage pendingWithdrawals = _pendingWithdrawals[
            address(symbioticVault)
        ];
        uint256 length = Math.min(pendingWithdrawals.length(), maxEpochs);
        for (uint256 i = 0; i < length; i++) {
            uint256 epoch = pendingWithdrawals.at(0);
            pendingWithdrawals.remove(epoch);
            symbioticVault.claim(address(vault), epoch);
        }
    }

    function deposit(ISymbioticVault symbioticVault, uint256 amount) external {
        _requireAtLeastOperator();
        require(
            _approvedSymbioticVaults.contains(address(symbioticVault)),
            "SymbioticVaultStrategy: vault not approved"
        );
        address collateral = symbioticVault.collateral();
        amount = Math.min(amount, IERC20(collateral).balanceOf(address(vault)));
        if (amount == 0) return;
        vaultModule.allowAndDeposit(symbioticVault, address(vault), amount);
    }
}
