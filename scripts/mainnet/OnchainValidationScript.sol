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
        uint256 n = 4;
        address[] memory curators = new address[](n);
        curators[0] = DeployConstants.STEAKHOUSE_MULTISIG;
        curators[1] = DeployConstants.RE7_MULTISIG;
        curators[2] = DeployConstants.AMPHOR_MULTISIG;
        curators[3] = DeployConstants.P2P_MULTISIG;

        string[] memory names = new string[](n);
        names[0] = DeployConstants.STEAKHOUSE_VAULT_NAME;
        names[1] = DeployConstants.RE7_VAULT_NAME;
        names[2] = DeployConstants.AMPHOR_VAULT_NAME;
        names[3] = DeployConstants.P2P_VAULT_NAME;

        string[] memory symbols = new string[](n);
        symbols[0] = DeployConstants.STEAKHOUSE_VAULT_SYMBOL;
        symbols[1] = DeployConstants.RE7_VAULT_SYMBOL;
        symbols[2] = DeployConstants.AMPHOR_VAULT_SYMBOL;
        symbols[3] = DeployConstants.P2P_VAULT_SYMBOL;

        DeployInterfaces.DeployParameters memory deployParams = DeployInterfaces
            .DeployParameters({
                deployer: DeployConstants.MAINNET_DEPLOYER,
                proxyAdmin: DeployConstants.MELLOW_LIDO_PROXY_MULTISIG,
                admin: DeployConstants.MELLOW_LIDO_MULTISIG,
                curator: address(0),
                lpTokenName: "",
                lpTokenSymbol: "",
                wstethDefaultBond: DeployConstants.WSTETH_DEFAULT_BOND,
                wstethDefaultBondFactory: DeployConstants
                    .WSTETH_DEFAULT_BOND_FACTORY,
                wsteth: DeployConstants.WSTETH,
                steth: DeployConstants.STETH,
                weth: DeployConstants.WETH,
                maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                initialDepositETH: DeployConstants.INITIAL_DEPOSIT_ETH,
                firstDepositETH: DeployConstants.FIRST_DEPOSIT_ETH,
                initializer: Initializer(
                    address(0x39c62c6308BeD7B0832CAfc2BeA0C0eDC7f2060c)
                ),
                initialImplementation: Vault(
                    payable(address(0xaf108ae0AD8700ac41346aCb620e828c03BB8848))
                ),
                erc20TvlModule: ERC20TvlModule(
                    address(0x1EB0e946D7d757d7b085b779a146427e40ABBCf8)
                ),
                defaultBondTvlModule: DefaultBondTvlModule(
                    address(0x1E1d1eD64e4F5119F60BF38B322Da7ea5A395429)
                ),
                defaultBondModule: DefaultBondModule(
                    address(0xD8619769fed318714d362BfF01CA98ac938Bdf9b)
                ),
                ratiosOracle: ManagedRatiosOracle(
                    address(0x955Ff4Cc738cDC009d2903196d1c94C8Cfb4D55d)
                ),
                priceOracle: ChainlinkOracle(
                    address(0x1Dc89c28e59d142688D65Bd7b22C4Fd40C2cC06d)
                ),
                wethAggregatorV3: IAggregatorV3(
                    address(0x6A8d8033de46c68956CCeBA28Ba1766437FF840F)
                ),
                wstethAggregatorV3: IAggregatorV3(
                    address(0x94336dF517036f2Bf5c620a1BC75a73A37b7bb16)
                ),
                defaultProxyImplementation: DefaultProxyImplementation(
                    address(0x02BB349832c58E892a20178b9696e2b93A3a9b0f)
                )
            });

        DeployInterfaces.DeploySetup[]
            memory setups = new DeployInterfaces.DeploySetup[](n);

        setups[0] = DeployInterfaces.DeploySetup({
            vault: Vault(payable(0xBEEF69Ac7870777598A04B2bd4771c71212E6aBc)),
            configurator: VaultConfigurator(
                address(0xe6180599432767081beA7deB76057Ce5883e73Be)
            ),
            depositWrapper: DepositWrapper(
                payable(0x24fee15BC11fF617c042283B58A3Bda6441Da145)
            ),
            defaultBondStrategy: DefaultBondStrategy(
                address(0x7a14b34a9a8EA235C66528dc3bF3aeFC36DFc268)
            ),
            proxyAdmin: ProxyAdmin(
                address(0xed792a3fDEB9044C70c951260AaAe974Fb3dB38F)
            ),
            validator: ManagedValidator(
                address(0xdB66693845a3f72e932631080Efb1A86536D0EA7)
            ),
            wstethAmountDeposited: 8554034897
        });

        setups[1] = DeployInterfaces.DeploySetup({
            vault: Vault(payable(0x84631c0d0081FDe56DeB72F6DE77abBbF6A9f93a)),
            configurator: VaultConfigurator(
                address(0x214d66d110060dA2848038CA0F7573486363cAe4)
            ),
            depositWrapper: DepositWrapper(
                payable(0x70cD3464A41B6692413a1Ba563b9D53955D5DE0d)
            ),
            defaultBondStrategy: DefaultBondStrategy(
                address(0xcE3A8820265AD186E8C1CeAED16ae97176D020bA)
            ),
            proxyAdmin: ProxyAdmin(
                address(0xF076CF343DCfD01BBA57dFEB5C74F7B015951fcF)
            ),
            validator: ManagedValidator(
                address(0x0483B89F632596B24426703E540e373083928a6A)
            ),
            wstethAmountDeposited: 8554034897
        });

        setups[2] = DeployInterfaces.DeploySetup({
            vault: Vault(payable(0x5fD13359Ba15A84B76f7F87568309040176167cd)),
            configurator: VaultConfigurator(
                address(0x2dEc4fDC225C1f71161Ea481E23D66fEaAAE2391)
            ),
            depositWrapper: DepositWrapper(
                payable(0xdC1741f9bD33DD791942CC9435A90B0983DE8665)
            ),
            defaultBondStrategy: DefaultBondStrategy(
                address(0xc3A149b5Ca3f4A5F17F5d865c14AA9DBb570F10A)
            ),
            proxyAdmin: ProxyAdmin(
                address(0xc24891B75ef55fedC377c5e6Ec59A850b12E23ac)
            ),
            validator: ManagedValidator(
                address(0xD2635fa0635126bAfdD430b9614c0280d37a76CA)
            ),
            wstethAmountDeposited: 8554034897
        });

        setups[3] = DeployInterfaces.DeploySetup({
            vault: Vault(payable(0x7a4EffD87C2f3C55CA251080b1343b605f327E3a)),
            configurator: VaultConfigurator(
                address(0x84b240E99d4C473b5E3dF1256300E2871412dDfe)
            ),
            depositWrapper: DepositWrapper(
                payable(0x41A1FBEa7Ace3C3a6B66a73e96E5ED07CDB2A34d)
            ),
            defaultBondStrategy: DefaultBondStrategy(
                address(0xA0ea6d4fe369104eD4cc18951B95C3a43573C0F6)
            ),
            proxyAdmin: ProxyAdmin(
                address(0x17AC6A90eD880F9cE54bB63DAb071F2BD3FE3772)
            ),
            validator: ManagedValidator(
                address(0x6AB116ac709c89D90Cc1F8cD0323617A9996bA7c)
            ),
            wstethAmountDeposited: 8554034897
        });

        for (uint256 i = 0; i < n; i++) {
            deployParams.curator = curators[i];
            deployParams.lpTokenName = names[i];
            deployParams.lpTokenSymbol = symbols[i];
            Vm.Log[] memory logs = parseLogs(address(setups[i].vault));
            validateParameters(deployParams, setups[i], (1 << 1));
            validateEvents(deployParams, setups[i], logs);

            console2.log(
                "The current onchain state and events for the vault have been successfully verified. Vault address:",
                address(setups[i].vault)
            );
        }
    }
}
