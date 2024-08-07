// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IVault as ISymbioticVault} from "../../interfaces/external/symbiotic/vault/IVault.sol";
import {ICollateral as ISymbioticCollateral} from "../../interfaces/external/symbiotic/collateral/ICollateral.sol";

import {IDefaultAccessControl} from "../../interfaces/utils/IDefaultAccessControl.sol";
import {ITvlModule} from "../../interfaces/modules/ITvlModule.sol";

contract SymbioticVaultTvlModule is ITvlModule {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address vault => mapping(address symbioticVault => uint256[] epochs))
        public symbioticEpochsForVault;

    mapping(address vault => EnumerableSet.AddressSet symbioticVaults)
        private _symbioticVaultsForVault;

    function addEpoch(address symbioticVault, uint256 epoch) external {
        address vaultAddress = msg.sender;
        uint256[] storage epochs = symbioticEpochsForVault[vaultAddress][
            symbioticVault
        ];
        for (uint256 i = 0; i < epochs.length; ) {
            if (epochs[i] == epoch) {
                return;
            }

            unchecked {
                ++i;
            }
        }
        epochs.push(epoch);
    }

    function removeEpoch(address symbioticVault, uint256 epoch) public {
        address vaultAddress = msg.sender;
        uint256[] storage epochs = symbioticEpochsForVault[vaultAddress][
            symbioticVault
        ];
        for (uint256 i = 0; i < epochs.length; ) {
            if (epochs[i] == epoch) {
                epochs[i] = epochs[epochs.length - 1];
                epochs.pop();
                return;
            }
            unchecked {
                ++i;
            }
        }
        revert("Epoch not found");
    }

    function removeEpochs(
        address symbioticVault,
        uint256[] memory epochs
    ) external {
        for (uint256 i = 0; i < epochs.length; ) {
            removeEpoch(symbioticVault, epochs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addSymbioticVault(address vault, address symbioticVault) external {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        _symbioticVaultsForVault[vault].add(symbioticVault);
    }

    function removeSymbioticVault(
        address vault,
        address symbioticVault
    ) external {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        _symbioticVaultsForVault[vault].remove(symbioticVault);
    }

    function tvl(address vault) external view returns (Data[] memory data) {
        EnumerableSet.AddressSet
            storage symbioticVaults = _symbioticVaultsForVault[vault];
        uint256 symbioticVaultCount = symbioticVaults.length();
        if (symbioticVaultCount == 0) return data;

        data = new Data[](symbioticVaultCount);
        for (uint256 i = 0; i < symbioticVaultCount; ) {
            ISymbioticVault symbioticVault = ISymbioticVault(
                symbioticVaults.at(i)
            );
            uint256[] memory epochs = symbioticEpochsForVault[vault][
                address(symbioticVault)
            ];
            data[i].token = address(0); // impossible to get base token, b.o. Symbiotic vault is not ERC20 compatibe.
            data[i].underlyingToken = ISymbioticCollateral(
                symbioticVault.collateral()
            ).asset();

            data[i].underlyingAmount = symbioticVault.activeBalanceOf(vault);
            for (uint256 j = 0; j < epochs.length; ) {
                data[i].underlyingAmount += symbioticVault.withdrawalsOf(
                    epochs[j],
                    vault
                );
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}
