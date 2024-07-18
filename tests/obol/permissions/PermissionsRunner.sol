// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/obol/Deploy.s.sol";

contract PermissionsRunner {
    function removeAddress(address[] memory array, address removingAddress) internal pure {
        uint256 n = array.length;
        uint256 index = n;
        for (uint256 i = 0; i < n; i++) {
            if (array[i] == removingAddress) {
                index = i;
                break;
            }
        }

        if (index < n) {
            if (index != n - 1) {
                array[index] = array[n - 1];
            }
            assembly {
                mstore(array, sub(n, 1))
            }
        }
    }
    
    function checkRoles(
        ManagedValidator validator,
        address addr,
        bool hasUserRoles,
        bool hasAllowAllSignatureRoles,
        bool hasAllowSignatureRoles
    ) internal view {
        uint256 userRoles = validator.userRoles(addr);
        if (hasUserRoles) {
            require(userRoles != 0, "ManagedValidator: User roles are not set");
        } else {
            require(userRoles == 0, "ManagedValidator: User roles are set");
        }
        uint256 allowAllSignatureRoles = validator.allowAllSignaturesRoles(
            addr
        );
        if (hasAllowAllSignatureRoles) {
            require(
                allowAllSignatureRoles != 0,
                "ManagedValidator: AllowAllSignatureRoles are not set"
            );
        } else {
            require(
                allowAllSignatureRoles == 0,
                "ManagedValidator: AllowAllSignatureRoles are set"
            );
        }

        // delegateCall
        uint256 allowSignatureRoles = validator.allowSignatureRoles(
            addr,
            IVault.delegateCall.selector
        );
        if (hasAllowSignatureRoles) {
            require(
                allowSignatureRoles != 0,
                "ManagedValidator: AllowSignatureRoles are not set (delegateCall)"
            );
        } else {
            require(
                allowSignatureRoles == 0,
                "ManagedValidator: AllowSignatureRoles are set (delegateCall)"
            );
        }

        // deposit
        allowSignatureRoles = validator.allowSignatureRoles(
            addr,
            IVault.deposit.selector
        );
        if (hasAllowSignatureRoles) {
            require(
                allowSignatureRoles != 0,
                "ManagedValidator: AllowSignatureRoles are not set (deposit)"
            );
        } else {
            require(
                allowSignatureRoles == 0,
                "ManagedValidator: AllowSignatureRoles are set (deposit)"
            );
        }
    }

    function validatePermissions(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup,
        address[] memory allAddresses
    ) public view {
        for (uint256 i = 0; i < allAddresses.length; i++) {
            if (allAddresses[i] != address(deployParams.stakingModule)) {
                require(
                    setup.configurator.isDelegateModuleApproved(
                        allAddresses[i]
                    ) == false,
                    "VaultConfigurator: random delegate module is approved"
                );
            } else {
                require(
                    setup.configurator.isDelegateModuleApproved(
                        allAddresses[i]
                    ) == true,
                    "VaultConfigurator: stakingModule is not approved"
                );
            }
        }
        
        {
            ManagedValidator validator = setup.validator;

            {
                // Addresses without any roles
                address[19] memory forbiddenAddresses = [
                    deployParams.deployer,
                    deployParams.proxyAdmin,
                    deployParams.curatorOperator,
                    deployParams.lidoLocator,
                    deployParams.wsteth,
                    deployParams.steth,
                    deployParams.weth,
                    address(deployParams.initialImplementation),
                    address(deployParams.initializer),
                    address(deployParams.erc20TvlModule),
                    address(deployParams.ratiosOracle),
                    address(deployParams.priceOracle),
                    address(deployParams.wethAggregatorV3),
                    address(deployParams.wstethAggregatorV3),
                    address(deployParams.defaultProxyImplementation),
                    address(setup.proxyAdmin),
                    address(setup.configurator),
                    address(setup.validator),
                    address(0)
                ];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    checkRoles(
                        validator,
                        forbiddenAddresses[i],
                        false, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                    removeAddress(allAddresses, forbiddenAddresses[i]);
                }
            }

            {
                // Addresses that have only userRoles
                address[3] memory forbiddenAddresses = [
                    deployParams.admin,
                    deployParams.curatorAdmin,
                    address(setup.strategy)
                ];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    checkRoles(
                        validator,
                        forbiddenAddresses[i],
                        true, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                    removeAddress(allAddresses, forbiddenAddresses[i]);
                }

            }

            {
                // Addresses that have only allowAllSignaturesRoles
                address[1] memory forbiddenAddresses = [
                    address(deployParams.stakingModule)
                ];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    checkRoles(
                        validator,
                        forbiddenAddresses[i],
                        false, // hasUserRoles
                        true, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                    removeAddress(allAddresses, forbiddenAddresses[i]);
                }
            }

            {
                // Addresses that have all roles except of allowAllSignaturesRoles
                address[1] memory forbiddenAddresses = [address(setup.vault)];

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    checkRoles(
                        validator,
                        forbiddenAddresses[i],
                        true, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        true // hasAllowSignatureRoles
                    );
                    removeAddress(allAddresses, forbiddenAddresses[i]);
                }
            }


            {
                // Addresses without any roles
                address[] memory forbiddenAddresses = allAddresses;

                for (uint256 i = 0; i < forbiddenAddresses.length; i++) {
                    checkRoles(
                        validator,
                        forbiddenAddresses[i],
                        false, // hasUserRoles
                        false, // hasAllowAllSignatureRoles
                        false // hasAllowSignatureRoles
                    );
                }

            }
        }
    }
}
