// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

import "./Validator.sol";
import "./EventValidator.sol";

contract OnchainValidationScript is Script, Validator, EventValidator {
    struct Data {
        bytes data;
        address emitter;
        bytes32[] topics;
    }

    function parseLogs(address vault) public view returns (Vm.Log[] memory e) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/scripts/mainnet/events_parser/events_",
            Strings.toHexString(vault),
            ".json"
        );
        bytes memory data = vm.parseJson(vm.readFile(path));
        Data[] memory d = abi.decode(data, (Data[]));
        e = new Vm.Log[](d.length);
        uint256 shift = 64;
        for (uint256 i = 0; i < d.length; i++) {
            bytes memory data_ = new bytes(d[i].data.length - shift);
            for (uint256 j = 0; j < data_.length; j++) {
                data_[j] = d[i].data[j + shift];
            }
            e[i] = VmSafe.Log({
                emitter: d[i].emitter,
                data: data_,
                topics: d[i].topics
            });
        }
    }

    function run() external view {
        DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
            .DeployParameters({
                curator: DeployConstants.STEAKHOUSE_MULTISIG,
                lpTokenName: DeployConstants.STEAKHOUSE_VAULT_TEST_NAME,
                lpTokenSymbol: DeployConstants.STEAKHOUSE_VAULT_TEST_SYMBOL,
                deployer: DeployConstants.MAINNET_TEST_DEPLOYER,
                proxyAdmin: DeployConstants.MELLOW_LIDO_TEST_PROXY_MULTISIG,
                admin: DeployConstants.MELLOW_LIDO_TEST_MULTISIG,
                wstethDefaultBond: DeployConstants.WSTETH_DEFAULT_BOND_TEST,
                wstethDefaultBondFactory: DeployConstants
                    .WSTETH_DEFAULT_BOND_FACTORY_TEST,
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_ETH,
                firstDepositETH: DeployConstants.FIRST_DEPOSIT_ETH,
                initializer: Initializer(
                    address(0x8f06BEB555D57F0D20dB817FF138671451084e24)
                ),
                initialImplementation: Vault(
                    payable(address(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F))
                ),
                erc20TvlModule: ERC20TvlModule(
                    address(0xCA60f449867c9101Ec80F8C611eaB39afE7bD638)
                ),
                defaultBondModule: DefaultBondModule(
                    address(0x204043f4bda61F719Ad232b4196E1bc4131a3096)
                ),
                defaultBondTvlModule: DefaultBondTvlModule(
                    address(0x48f758bd51555765EBeD4FD01c85554bD0B3c03B)
                ),
                ratiosOracle: ManagedRatiosOracle(
                    address(0x1437DCcA4e1442f20285Fb7C11805E7a965681e2)
                ),
                priceOracle: ChainlinkOracle(
                    address(0xA5046e9379B168AFA154504Cf16853B6a7728436)
                ),
                wethAggregatorV3: ConstantAggregatorV3(
                    address(0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09)
                ),
                wstethAggregatorV3: WStethRatiosAggregatorV3(
                    address(0x773ae8ca45D5701131CA84C58821a39DdAdC709c)
                ),
                defaultProxyImplementation: DefaultProxyImplementation(
                    address(0x538459eeA06A06018C70bf9794e1c7b298694828)
                )
            });
        DeployInterfaces.DeploySetup memory setup = DeployInterfaces
            .DeploySetup({
                vault: Vault(
                    payable(0xa77a8D25cEB4B9F38A711850751edAc70d7b91b0)
                ),
                configurator: VaultConfigurator(
                    address(0x7dB7dA79AF0Fe678634A51e1f57a091Fd485f7f8)
                ),
                depositWrapper: DepositWrapper(
                    payable(0x9CaA80709b4F9a72b70efc7Db4bE0150Bf362126)
                ),
                defaultBondStrategy: DefaultBondStrategy(
                    address(0x378F3AD5F48524bb2cD9A0f88B6AA525BaB2cB62)
                ),
                proxyAdmin: ProxyAdmin(
                    address(0x638113B8941327E4B0213Eefcb1319EC664DFD16)
                ),
                validator: ManagedValidator(
                    address(0xd1928e2675a9be18f08d9aCe1A8008aaDEa3d813)
                ),
                wstethAmountDeposited: 8557152514
            });

        Vm.Log[] memory logs = parseLogs(address(setup.vault));
        validateParameters(deployParams, setup, (1 << 1) | (1 << 0));
        validateEvents(deployParams, setup, logs);

        console2.log(
            "The current onchain state and events for the vault have been successfully verified. Vault address:",
            address(setup.vault)
        );
    }
}
