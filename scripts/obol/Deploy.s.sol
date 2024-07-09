// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployScript.sol";
import "./DeployInterfaces.sol";

contract Deploy is Script, DeployScript {
    function run() external {
        // DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
        //     .DeployParameters({
        //         deployer: DeployConstants.HOLESKY_DEPLOYER,
        //         proxyAdmin: DeployConstants._VAULT_ADMIN,
        //         admin: DeployConstants.VAULT_ADMIN,
        //         curatorAdmin: DeployConstants.CURATOR_ADMIN,
        //         curatorOperator: DeployConstants.CURATOR_ADMIN,
        //         lpTokenName: DeployConstants.MELLOW_VAULT_NAME,
        //         lpTokenSymbol: DeployConstants.MELLOW_VAULT_SYMBOL,
        //         wsteth: DeployConstants.WSTETH,
        //         steth: DeployConstants.STETH,
        //         weth: DeployConstants.WETH,
        //         maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
        //         initialDepositWETH: DeployConstants.INITIAL_DEPOSIT_ETH,
        //         firstDepositWETH: DeployConstants.FIRST_DEPOSIT_ETH,
        //         initializer: Initializer(address(0)),
        //         initialImplementation: Vault(payable(address(0))),
        //         erc20TvlModule: ERC20TvlModule(address(0)),
        //         stakingModule: StakingModule(address(0)),
        //         ratiosOracle: ManagedRatiosOracle(address(0)),
        //         priceOracle: ChainlinkOracle(address(0)),
        //         wethAggregatorV3: IAggregatorV3(address(0)),
        //         wstethAggregatorV3: IAggregatorV3(address(0)),
        //         defaultProxyImplementation: DefaultProxyImplementation(
        //             address(0)
        //         )
        //     });
        // vm.startBroadcast(uint256(bytes32(vm.envBytes("HOLESKY_DEPLOYER"))));
        // IWeth(DeployConstants.WETH).deposit{
        //     value: deployParams.initialDepositWETH * 10
        // }();
        // deployParams = commonContractsDeploy(deployParams);
        // DeployInterfaces.DeploySetup memory setup;
        // (deployParams, setup) = deploy(deployParams);
        // vm.stopBroadcast();
        // logSetup(setup);
        // logDeployParams(deployParams);
        // revert("success");
    }

    function logSetup(DeployInterfaces.DeploySetup memory setup) internal view {
        console2.log(IERC20Metadata(address(setup.vault)).name());
        console2.log("Vault: ", address(setup.vault));
        console2.log("Configurator: ", address(setup.configurator));
        console2.log("Validator: ", address(setup.validator));
        console2.log("strategy: ", address(setup.strategy));
        console2.log(
            "TransparentUpgradeableProxy-ProxyAdmin: ",
            address(setup.proxyAdmin)
        );
        console2.log("---------------------------");
        block.timestamp;
    }

    function logDeployParams(
        DeployInterfaces.DeployParameters memory deployParams
    ) internal view {
        console2.log("Deployer: ", address(deployParams.deployer));
        console2.log("ProxyAdmin: ", address(deployParams.proxyAdmin));
        console2.log("Admin: ", address(deployParams.admin));
        console2.log("Curator admin: ", address(deployParams.curatorAdmin));
        console2.log(
            "Curator operator: ",
            address(deployParams.curatorOperator)
        );
        console2.log("Wsteth: ", address(deployParams.wsteth));
        console2.log("Steth: ", address(deployParams.steth));
        console2.log("Weth: ", address(deployParams.weth));
        console2.log("MaximalTotalSupply: ", deployParams.maximalTotalSupply);
        console2.log("LpTokenName: ", deployParams.lpTokenName);
        console2.log("LpTokenSymbol: ", deployParams.lpTokenSymbol);
        console2.log("initialDepositWETH: ", deployParams.initialDepositWETH);
        console2.log("Initializer: ", address(deployParams.initializer));
        console2.log(
            "InitialImplementation: ",
            address(deployParams.initialImplementation)
        );
        console2.log("Erc20TvlModule: ", address(deployParams.erc20TvlModule));
        console2.log("StakingModule: ", address(deployParams.stakingModule));
        console2.log("RatiosOracle: ", address(deployParams.ratiosOracle));
        console2.log("PriceOracle: ", address(deployParams.priceOracle));
        console2.log(
            "WethAggregatorV3: ",
            address(deployParams.wethAggregatorV3)
        );
        console2.log(
            "WstethAggregatorV3: ",
            address(deployParams.wstethAggregatorV3)
        );
        console2.log(
            "DefaultProxyImplementation: ",
            address(deployParams.defaultProxyImplementation)
        );
        block.timestamp;
    }
}
