// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet/Deploy.s.sol";

contract IntegrationTest is DeployScript, Validator, Test {

    function testDeploy() external {
        DeployInterfaces.DeployParameters memory deployParams;

        bool test = true;

        address curator = DeployConstants.STEAKHOUSE_MULTISIG;
        string memory name = DeployConstants.STEAKHOUSE_VAULT_TEST_NAME;
        string memory symbol = DeployConstants.STEAKHOUSE_VAULT_TEST_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_TEST_DEPLOYER;
        vm.startBroadcast(
            uint256(bytes32(vm.envBytes("MAINNET_TEST_DEPLOYER")))
        );

        deployParams.proxyAdmin = DeployConstants
            .MELLOW_LIDO_TEST_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        // only for testing purposes
        if (test) {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND_TEST;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY_TEST;
        } else {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY;
        }

        deployParams.wsteth = DeployConstants.WSTETH;
        deployParams.steth = DeployConstants.STETH;
        deployParams.weth = DeployConstants.WETH;

        deployParams.maximalTotalSupply = DeployConstants.MAXIMAL_TOTAL_SUPPLY;
        deployParams.initialDepositETH = DeployConstants.INITIAL_DEPOSIT_ETH;
        deployParams.firstDepositETH = DeployConstants.FIRST_DEPOSIT_ETH;
        deployParams.timeLockDelay = DeployConstants.TIMELOCK_TEST_DELAY;

        DeployInterfaces.DeploySetup memory setup;

        deployParams.initializer = Initializer(
            0x8f06BEB555D57F0D20dB817FF138671451084e24
        );
        deployParams.initialImplementation = Vault(
            payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)
        );
        deployParams.erc20TvlModule = ERC20TvlModule(
            0xCA60f449867c9101Ec80F8C611eaB39afE7bD638
        );
        deployParams.defaultBondModule = DefaultBondModule(
            0x204043f4bda61F719Ad232b4196E1bc4131a3096
        );
        deployParams.defaultBondTvlModule = DefaultBondTvlModule(
            0x48f758bd51555765EBeD4FD01c85554bD0B3c03B
        );
        deployParams.ratiosOracle = ManagedRatiosOracle(
            0x1437DCcA4e1442f20285Fb7C11805E7a965681e2
        );
        deployParams.priceOracle = ChainlinkOracle(
            0xA5046e9379B168AFA154504Cf16853B6a7728436
        );
        deployParams.wethAggregatorV3 = ConstantAggregatorV3(
            0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09
        );
        deployParams.wstethAggregatorV3 = WStethRatiosAggregatorV3(
            0x773ae8ca45D5701131CA84C58821a39DdAdC709c
        );
        deployParams.defaultProxyImplementation = DefaultProxyImplementation(
            0x538459eeA06A06018C70bf9794e1c7b298694828
        );

        deployParams = commonContractsDeploy(deployParams);
        deployParams.curator = curator;
        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;

        vm.recordLogs();
        (deployParams, setup) = deploy(deployParams);

        validateParameters(deployParams, setup);
        if (false) {
            setup.depositWrapper.deposit{
                value: deployParams.firstDepositETH
            }(
                deployParams.deployer,
                address(0),
                deployParams.firstDepositETH,
                0,
                type(uint256).max
            );
        }

        vm.stopBroadcast();
    }
}