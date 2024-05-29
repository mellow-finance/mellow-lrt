// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployLibrary.sol";

library ValidationLibrary {
    function validateParameters(
        DeployLibrary.DeployParameters memory deployParams,
        DeployLibrary.DeploySetup memory setup
    ) external view {
        // vault permissions

        bytes32 ADMIN_ROLE = keccak256("admin");
        bytes32 ADMIN_DELEGATE_ROLE = keccak256("admin_delegate");
        bytes32 OPERATOR_ROLE = keccak256("operator");

        uint256 ADMIN_ROLE_MASK = 1 << 255;
        uint256 DEPOSITOR_ROLE_MASK = 1 << 0;
        uint256 DEFAULT_BOND_STRATEGY_ROLE_MASK = 1 << 1;
        uint256 DEFAULT_BOND_MODULE_ROLE_MASK = 1 << 2;

        {
            Vault vault = setup.vault;
            require(vault.getRoleMemberCount(ADMIN_ROLE) == 1);
            require(vault.hasRole(ADMIN_ROLE, deployParams.admin));
            require(vault.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 2);
            require(
                vault.hasRole(
                    ADMIN_DELEGATE_ROLE,
                    address(setup.restrictingKeeper)
                )
            );
            require(
                vault.hasRole(
                    ADMIN_DELEGATE_ROLE,
                    address(deployParams.curator)
                )
            );
            require(vault.getRoleMemberCount(OPERATOR_ROLE) == 1);
            require(
                vault.hasRole(OPERATOR_ROLE, address(setup.defaultBondStrategy))
            );
        }

        // DefaultBondStrategy permissions
        {
            DefaultBondStrategy strategy = setup.defaultBondStrategy;
            require(strategy.getRoleMemberCount(ADMIN_ROLE) == 2);
            require(strategy.hasRole(ADMIN_ROLE, deployParams.admin));
            require(strategy.hasRole(ADMIN_ROLE, deployParams.curator));
            require(strategy.getRoleMemberCount(ADMIN_DELEGATE_ROLE) == 0);
            require(strategy.getRoleMemberCount(OPERATOR_ROLE) == 0);
        }

        // Managed validator permissions
        {
            ManagedValidator validator = setup.validator;
            require(validator.publicRoles() == DEPOSITOR_ROLE_MASK);

            require(validator.userRoles(deployParams.deployer) == 0);
            require(validator.userRoles(deployParams.admin) == ADMIN_ROLE_MASK);
            require(
                validator.userRoles(deployParams.curator) == ADMIN_ROLE_MASK
            );

            require(
                validator.userRoles(address(setup.defaultBondStrategy)) ==
                    DEFAULT_BOND_STRATEGY_ROLE_MASK
            );
            require(
                validator.userRoles(address(setup.vault)) ==
                    DEFAULT_BOND_MODULE_ROLE_MASK
            );

            require(
                validator.allowAllSignaturesRoles(
                    address(setup.defaultBondStrategy)
                ) == 0
            );
            require(
                validator.allowAllSignaturesRoles(address(setup.vault)) ==
                    DEFAULT_BOND_STRATEGY_ROLE_MASK
            );
            require(
                validator.allowAllSignaturesRoles(
                    address(setup.defaultBondModule)
                ) == DEFAULT_BOND_MODULE_ROLE_MASK
            );
            require(
                validator.allowSignatureRoles(
                    address(setup.vault),
                    IVault.deposit.selector
                ) == DEPOSITOR_ROLE_MASK
            );
        }

        // vault balances
        {
            require(setup.vault.balanceOf(deployParams.deployer) == 0);
            require(
                setup.vault.balanceOf(address(setup.vault)) ==
                    deployParams.initialDepositETH
            );
            require(
                setup.vault.totalSupply() == deployParams.initialDepositETH
            );
            require(
                IERC20(deployParams.wsteth).balanceOf(address(setup.vault)) == 0
            );
            uint256 bondBalance = IERC20(deployParams.wstethDefaultBond)
                .balanceOf(address(setup.vault));
            require(bondBalance == setup.wstethAmountDeposited);
            require(
                IERC20(deployParams.wsteth).balanceOf(
                    deployParams.wstethDefaultBond
                ) == bondBalance
            );
            uint256 expectedStethAmount = IWSteth(deployParams.wsteth)
                .getStETHByWstETH(bondBalance);
            // at most 2 weis loss due to eth->steth && steth->wsteth conversions
            require(
                deployParams.initialDepositETH - 2 wei <= expectedStethAmount &&
                    expectedStethAmount <=
                    deployParams.initialDepositETH - 2 wei
            );
        }
    }
}
