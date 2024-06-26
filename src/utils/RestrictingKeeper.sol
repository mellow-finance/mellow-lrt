// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../VaultConfigurator.sol";

contract RestrictingKeeper {
    function processConfigurators(
        VaultConfigurator[] memory configurators
    ) external {
        for (uint256 i = 0; i < configurators.length; i++) {
            VaultConfigurator configurator = configurators[i];
            configurator.rollbackStagedBaseDelay();
            configurator.rollbackStagedMaximalTotalSupplyDelay();
            configurator.rollbackStagedMaximalTotalSupply();
        }
    }
}
