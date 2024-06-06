// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployLibrary.sol";

library ValidationLibrary {
    function validateParameters(
        DeployLibrary.DeployParameters memory deployParams,
        DeployLibrary.DeploySetup memory setup
    ) external view {
        require(
            setup.vault.getRoleMemberCount(setup.vault.ADMIN_DELEGATE_ROLE()) ==
                1
        );
        require(setup.vault.getRoleMemberCount(setup.vault.ADMIN_ROLE()) == 1);
        require(
            setup.vault.hasRole(
                setup.vault.ADMIN_ROLE(),
                deployParams.vaultAdmin
            )
        );
        require(
            setup.vault.hasRole(
                setup.vault.ADMIN_DELEGATE_ROLE(),
                address(setup.restrictingKeeper)
            )
        );
        require(
            !setup.vault.hasRole(
                setup.vault.ADMIN_DELEGATE_ROLE(),
                deployParams.deployer
            )
        );
    }

    function test() public pure {}
}
