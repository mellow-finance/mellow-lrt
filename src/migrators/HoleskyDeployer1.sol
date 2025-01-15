// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../scripts/mainnet/DeployInterfaces.sol";

contract HoleskyDeployer1 {
    using SafeERC20 for IERC20;

    function deploy(
        DeployInterfaces.DeployParameters memory deployParams,
        bytes32 salt,
        address expectedProxyAdmin
    )
        external
        payable
        returns (
            DeployInterfaces.DeployParameters memory,
            DeployInterfaces.DeploySetup memory s
        )
    {
        {
            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
                salt: salt
            }(
                address(deployParams.initializer),
                address(deployParams.deployer),
                new bytes(0)
            );
            if (expectedProxyAdmin == address(0)) {
                s.vault = Vault(payable(proxy));
                return (deployParams, s);
            }

            Initializer(address(proxy)).initialize(
                deployParams.lpTokenName,
                deployParams.lpTokenSymbol,
                deployParams.deployer
            );

            s.proxyAdmin = ProxyAdmin(expectedProxyAdmin);
            s.proxyAdmin.upgradeAndCall(
                ITransparentUpgradeableProxy(address(proxy)),
                address(deployParams.initialImplementation),
                new bytes(0)
            );

            s.proxyAdmin.transferOwnership(address(deployParams.proxyAdmin));
            s.vault = Vault(payable(proxy));
        }

        s.vault.grantRole(s.vault.ADMIN_DELEGATE_ROLE(), deployParams.deployer);
        s.vault.grantRole(s.vault.ADMIN_ROLE(), deployParams.admin);

        s.configurator = s.vault.configurator();

        s.vault.addTvlModule(address(deployParams.erc20TvlModule));
        s.vault.addTvlModule(address(deployParams.defaultBondTvlModule));

        s.vault.addToken(deployParams.wsteth);
        // oracles setup
        {
            uint128[] memory ratiosX96 = new uint128[](1);
            ratiosX96[0] = 2 ** 96; // WSTETH deposit
            deployParams.ratiosOracle.updateRatios(
                address(s.vault),
                true,
                ratiosX96
            );
            ratiosX96[0] = 2 ** 96; // WSTETH withdrawal
            deployParams.ratiosOracle.updateRatios(
                address(s.vault),
                false,
                ratiosX96
            );

            s.configurator.stageRatiosOracle(
                address(deployParams.ratiosOracle)
            );
            s.configurator.commitRatiosOracle();

            address[] memory tokens = new address[](2);
            tokens[0] = deployParams.weth;
            tokens[1] = deployParams.wsteth;
            IChainlinkOracle.AggregatorData[]
                memory data = new IChainlinkOracle.AggregatorData[](2);
            data[0].aggregatorV3 = address(deployParams.wethAggregatorV3);
            data[0].maxAge = 0;
            data[1].aggregatorV3 = address(deployParams.wstethAggregatorV3);
            data[1].maxAge = 0;

            deployParams.priceOracle.setBaseToken(
                address(s.vault),
                deployParams.weth
            );
            deployParams.priceOracle.setChainlinkOracles(
                address(s.vault),
                tokens,
                data
            );

            s.configurator.stagePriceOracle(address(deployParams.priceOracle));
            s.configurator.commitPriceOracle();
        }

        // setting initial total supply
        {
            s.configurator.stageMaximalTotalSupply(
                deployParams.maximalTotalSupply
            );
            s.configurator.commitMaximalTotalSupply();
        }

        // setting params for wsteth default bond in defaultBondTvlModule
        {
            address[] memory supportedBonds = new address[](1);
            supportedBonds[0] = deployParams.wstethDefaultBond;
            deployParams.defaultBondTvlModule.setParams(
                address(s.vault),
                supportedBonds
            );
        }

        s.configurator.stageDelegateModuleApproval(
            address(deployParams.defaultBondModule)
        );
        s.configurator.commitDelegateModuleApproval(
            address(deployParams.defaultBondModule)
        );

        s.defaultBondStrategy = new DefaultBondStrategy(
            deployParams.deployer,
            s.vault,
            deployParams.erc20TvlModule,
            deployParams.defaultBondModule
        );

        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.ADMIN_ROLE(),
            deployParams.admin
        );
        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.grantRole(
            s.defaultBondStrategy.OPERATOR(),
            address(deployParams.curator)
        );
        {
            s.configurator.stageDepositCallback(address(s.defaultBondStrategy));
            s.configurator.commitDepositCallback();
        }

        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0].bond = deployParams.wstethDefaultBond;
            data[0].ratioX96 = DeployConstants.Q96;
            s.defaultBondStrategy.setData(deployParams.wsteth, data);
        }

        // validators setup
        s.validator = new ManagedValidator(deployParams.deployer);
        s.validator.grantRole(
            deployParams.admin,
            DeployConstants.ADMIN_ROLE_BIT // ADMIN_ROLE_MASK = (1 << 255)
        );
        {
            s.validator.grantRole(
                address(s.defaultBondStrategy),
                DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );
            s.validator.grantContractRole(
                address(s.vault),
                DeployConstants.DEFAULT_BOND_STRATEGY_ROLE_BIT
            );

            s.validator.grantRole(
                address(s.vault),
                DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT
            );
        }
        return (deployParams, s);
    }
}
