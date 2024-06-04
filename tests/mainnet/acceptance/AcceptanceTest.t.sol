// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet/Validator.sol";

contract Acceptance is Validator, Test {
    function testSteakHouseDeployment() external view {
        DeployInterfaces.DeployParameters memory params;
        DeployInterfaces.DeploySetup memory setup;

        setup.vault = Vault(
            payable(0xa77a8D25cEB4B9F38A711850751edAc70d7b91b0)
        );
        setup.configurator = VaultConfigurator(
            0x7dB7dA79AF0Fe678634A51e1f57a091Fd485f7f8
        );
        setup.validator = ManagedValidator(
            0xd1928e2675a9be18f08d9aCe1A8008aaDEa3d813
        );
        setup.defaultBondStrategy = DefaultBondStrategy(
            0x378F3AD5F48524bb2cD9A0f88B6AA525BaB2cB62
        );
        setup.depositWrapper = DepositWrapper(
            payable(0x9CaA80709b4F9a72b70efc7Db4bE0150Bf362126)
        );
        setup.timeLockedCurator = TimelockController(
            payable(0xF1504311dB8df3e02D56Ef6a2278188969cC2EDA)
        );
        setup.wstethAmountDeposited = 8557152514;

        params.deployer = 0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
        params.proxyAdmin = 0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
        params.admin = 0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
        params.curator = 0x2E93913A796a6C6b2bB76F41690E78a2E206Be54;
        params
            .wstethDefaultBondFactory = 0x3F95a719260ce6ec9622bC549c9adCff9edf16D9;
        params.wstethDefaultBond = 0xB56dA788Aa93Ed50F50e0d38641519FfB3C3D1Eb;
        params.wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        params.steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        params.weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        params.maximalTotalSupply = 10000000000000000000000;
        params.lpTokenName = "Steakhouse Vault (test)";
        params.lpTokenSymbol = "steakLRT (test)";
        params.initialDepositETH = 10000000000;
        params.timeLockDelay = 60;
        params.initialImplementation = Vault(
            payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)
        );
        params.initializer = Initializer(
            0x8f06BEB555D57F0D20dB817FF138671451084e24
        );
        params.erc20TvlModule = ERC20TvlModule(
            0xCA60f449867c9101Ec80F8C611eaB39afE7bD638
        );
        params.defaultBondTvlModule = DefaultBondTvlModule(
            0x48f758bd51555765EBeD4FD01c85554bD0B3c03B
        );
        params.defaultBondModule = DefaultBondModule(
            0x204043f4bda61F719Ad232b4196E1bc4131a3096
        );
        params.ratiosOracle = ManagedRatiosOracle(
            0x1437DCcA4e1442f20285Fb7C11805E7a965681e2
        );
        params.priceOracle = ChainlinkOracle(
            0xA5046e9379B168AFA154504Cf16853B6a7728436
        );
        params.wethAggregatorV3 = IAggregatorV3(
            0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09
        );
        params.wstethAggregatorV3 = IAggregatorV3(
            0x773ae8ca45D5701131CA84C58821a39DdAdC709c
        );
        params.defaultProxyImplementation = DefaultProxyImplementation(
            0x538459eeA06A06018C70bf9794e1c7b298694828
        );

        // oz proxy Proxy Admin: 0x638113B8941327E4B0213Eefcb1319EC664DFD16
        validateParameters(params, setup);
    }
}
