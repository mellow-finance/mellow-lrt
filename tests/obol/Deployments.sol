// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../scripts/obol/DeployInterfaces.sol";

library Deployments {
    struct Deployment {
        DeployInterfaces.DeployParameters deployParams;
        DeployInterfaces.DeploySetup deploySetup;
    }

    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant HOLESKY_CHAIN_ID = 17000;

    function deployParameters()
        external
        view
        returns (DeployInterfaces.DeployParameters memory)
    {
        uint256 id = block.chainid;
        if (id == MAINNET_CHAIN_ID)
            return
                DeployInterfaces.DeployParameters(
                    DeployConstants.MAINNET_DEPLOYER,
                    DeployConstants.MAINNET_PROXY_VAULT_ADMIN,
                    DeployConstants.MAINNET_VAULT_ADMIN,
                    DeployConstants.MAINNET_CURATOR_ADMIN,
                    DeployConstants.MAINNET_CURATOR_OPERATOR,
                    DeployConstants.MAINNET_LIDO_LOCATOR,
                    DeployConstants.MAINNET_WSTETH,
                    DeployConstants.MAINNET_STETH,
                    DeployConstants.MAINNET_WETH,
                    DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                    DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
                    DeployConstants.MELLOW_VAULT_NAME,
                    DeployConstants.MELLOW_VAULT_SYMBOL,
                    DeployConstants.INITIAL_DEPOSIT_ETH,
                    Vault(payable(address(0))),
                    Initializer(address(0)),
                    ERC20TvlModule(address(0)),
                    StakingModule(address(0)),
                    ManagedRatiosOracle(address(0)),
                    ChainlinkOracle(address(0)),
                    IAggregatorV3(address(0)),
                    IAggregatorV3(address(0)),
                    DefaultProxyImplementation(address(0))
                );

        if (id == HOLESKY_CHAIN_ID)
            return
                DeployInterfaces.DeployParameters(
                    DeployConstants.HOLESKY_DEPLOYER,
                    DeployConstants.HOLESKY_PROXY_VAULT_ADMIN,
                    DeployConstants.HOLESKY_VAULT_ADMIN,
                    DeployConstants.HOLESKY_CURATOR_ADMIN,
                    DeployConstants.HOLESKY_CURATOR_OPERATOR,
                    DeployConstants.HOLESKY_LIDO_LOCATOR,
                    DeployConstants.HOLESKY_WSTETH,
                    DeployConstants.HOLESKY_STETH,
                    DeployConstants.HOLESKY_WETH,
                    DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                    DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
                    DeployConstants.MELLOW_VAULT_NAME,
                    DeployConstants.MELLOW_VAULT_SYMBOL,
                    DeployConstants.INITIAL_DEPOSIT_ETH,
                    Vault(payable(address(0))),
                    Initializer(address(0)),
                    ERC20TvlModule(address(0)),
                    StakingModule(address(0)),
                    ManagedRatiosOracle(address(0)),
                    ChainlinkOracle(address(0)),
                    IAggregatorV3(address(0)),
                    IAggregatorV3(address(0)),
                    DefaultProxyImplementation(address(0))
                );

        revert("Deployments: Unsupported chain");
    }

    function deployments()
        external
        view
        returns (Deployment[] memory deployments_)
    {
        uint256 id = block.chainid;
        if (id == MAINNET_CHAIN_ID) {
            deployments_ = new Deployment[](1);
            deployments_[0].deployParams = DeployInterfaces.DeployParameters(
                DeployConstants.MAINNET_DEPLOYER,
                DeployConstants.MAINNET_PROXY_VAULT_ADMIN,
                DeployConstants.MAINNET_VAULT_ADMIN,
                DeployConstants.MAINNET_CURATOR_ADMIN,
                DeployConstants.MAINNET_CURATOR_OPERATOR,
                DeployConstants.MAINNET_LIDO_LOCATOR,
                DeployConstants.MAINNET_WSTETH,
                DeployConstants.MAINNET_STETH,
                DeployConstants.MAINNET_WETH,
                DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
                DeployConstants.MELLOW_VAULT_NAME,
                DeployConstants.MELLOW_VAULT_SYMBOL,
                DeployConstants.INITIAL_DEPOSIT_ETH,
                Vault(payable(0xe2D2E90122cb203CF1565a37ef90a256843A825A)),
                Initializer(0x969A0c7699ad0AC38fE05117c81D662762443E07),
                ERC20TvlModule(0x2c73350310C2b8c721d8192bd7620D1DCB1219ce),
                StakingModule(0xD570E16E3B62F05EcF3ff2706D331B7f56453adA),
                ManagedRatiosOracle(0xFeAFe509fae65962EF81555E3f078D58aF7ca3e9),
                ChainlinkOracle(0x39D5F9aEbBEcba99ED5d707b11d790387B5acB63),
                IAggregatorV3(0x278798AE6ea76ae75b381eA0D8DF140C1D5a7712),
                IAggregatorV3(0x966a3b1c9d477D113630290F037b12349649d1bd),
                DefaultProxyImplementation(
                    0xB8eF363E1909665c18BF0CB72Cba9a8152413A2E
                )
            );
            deployments_[0].deploySetup = DeployInterfaces.DeploySetup(
                Vault(payable(0x5E362eb2c0706Bd1d134689eC75176018385430B)),
                ProxyAdmin(0x8E6C80c41450D3fA7B1Fd0196676b99Bfb34bF48),
                IVaultConfigurator(0xDee41701310f48744e6Bb4A5df6B5e714cE49133),
                ManagedValidator(0xA1b3a352c3fC7cfcBD36381CC2D0b157d6843473),
                SimpleDVTStakingStrategy(
                    0x078b1C03d14652bfeeDFadf7985fdf2D8a2e8108
                )
            );
            return deployments_;
        }
        if (id == HOLESKY_CHAIN_ID) {
            deployments_ = new Deployment[](1);
            deployments_[0].deployParams = DeployInterfaces.DeployParameters(
                DeployConstants.HOLESKY_DEPLOYER,
                DeployConstants.HOLESKY_PROXY_VAULT_ADMIN,
                DeployConstants.HOLESKY_VAULT_ADMIN,
                DeployConstants.HOLESKY_CURATOR_ADMIN,
                DeployConstants.HOLESKY_CURATOR_OPERATOR,
                DeployConstants.HOLESKY_LIDO_LOCATOR,
                DeployConstants.HOLESKY_WSTETH,
                DeployConstants.HOLESKY_STETH,
                DeployConstants.HOLESKY_WETH,
                DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
                "Distributed Validator stETH",
                "DVstETH",
                DeployConstants.INITIAL_DEPOSIT_ETH,
                Vault(payable(0x1EF5eaB67AE611092b8003D42cA684bD4C196fFc)),
                Initializer(0x279F68f4a9b5dB11fC32B04Cb4F56794fad48242),
                ERC20TvlModule(0x0e4701020700f53b0a8903D7a3A6209Ae97a1BC0),
                StakingModule(0x3B342b4BA8cc065C6b115A18dbcf1c2B54FC93E2),
                ManagedRatiosOracle(0x64e70C5B72412efe67Ea4872BfCb80570aC5e93f),
                ChainlinkOracle(0x7C76B8411e0C530F6aa86858d1B12d6e62845bc6),
                IAggregatorV3(0x329eA0287b8198C59FD8D89D8F2bb0316Bd35d67),
                IAggregatorV3(0xA1CF7999E6Befe221581E3F74AAd442E88618ca0),
                DefaultProxyImplementation(
                    0x202aeBF79bC49f39F4e6E72973f48c361349e9D6
                )
            );
            deployments_[0].deploySetup = DeployInterfaces.DeploySetup(
                Vault(payable(0x7F31eb85aBE328EBe6DD07f9cA651a6FE623E69B)),
                ProxyAdmin(0xE60063c6CaCB23146ceA11dEE0bF3C0C887b8136),
                IVaultConfigurator(0x5aab3E3E9D627f2d027808c3780f7d746C8E8138),
                ManagedValidator(0xf02502935f4060D7f7Ebadb95627fAD6912173e1),
                SimpleDVTStakingStrategy(
                    0x17d53Fe02084953dA820986cc4912F7B12338306
                )
            );

            return deployments_;
        }

        revert("Deployments: Unsupported chain");
    }
}
