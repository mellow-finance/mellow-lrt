// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../src/Vault.sol";
import "../../src/VaultConfigurator.sol";
import "../../src/validators/AllowAllValidator.sol";
import "../../src/validators/ManagedValidator.sol";
import "../../src/validators/DefaultBondValidator.sol";
import "../../src/validators/ERC20SwapValidator.sol";
import "../../src/utils/DefaultAccessControl.sol";
import "../../src/utils/DepositWrapper.sol";
import "../../src/utils/WethDepositWrapper.sol";
import "../../src/strategies/SimpleDVTStakingStrategy.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/oracles/ChainlinkOracle.sol";
import "../../src/oracles/ManagedRatiosOracle.sol";
import "../../src/oracles/ConstantAggregatorV3.sol";
import "../../src/oracles/WStethRatiosAggregatorV3.sol";
import "../../src/oracles/VaultRateOracle.sol";
import "../../src/modules/erc20/ERC20TvlModule.sol";
import "../../src/modules/erc20/ERC20SwapModule.sol";
import "../../src/modules/erc20/ManagedTvlModule.sol";
import "../../src/modules/obol/StakingModule.sol";

import "../../src/modules/symbiotic/DefaultBondModule.sol";
import "../../src/modules/symbiotic/DefaultBondTvlModule.sol";

import "../../src/libraries/external/FullMath.sol";

import "../../src/interfaces/external/lido/ISteth.sol";
import "../../src/interfaces/external/lido/IWSteth.sol";
import "../../src/interfaces/external/lido/IStakingRouter.sol";
import "../../src/interfaces/external/lido/IDepositContract.sol";
import "../../src/interfaces/external/uniswap/ISwapRouter.sol";

import "../../src/security/AdminProxy.sol";
import "../../src/security/DefaultProxyImplementation.sol";
import "../../src/security/Initializer.sol";

import "../../src/utils/RestrictingKeeper.sol";

import "./mocks/VaultMock.sol";
import "./mocks/DefaultBondMock.sol";
import "./mocks/ChainlinkOracleMock.sol";
import "./mocks/WithdrawalCallbackMock.sol";
import "./mocks/DepositCallbackMock.sol";
import "./mocks/FullMathMock.sol";
import "./mocks/AggregatorV3Mock.sol";

library Constants {
    address public constant VAULT_ADMIN =
        address(bytes20(keccak256("VAULT_ADMIN")));
    address public constant PROTOCOL_GOVERNANCE_ADMIN =
        address(bytes20(keccak256("PROTOCOL_GOVERNANCE_ADMIN")));
    address public constant DEPOSITOR =
        address(bytes20(keccak256("DEPOSITOR")));

    uint8 public constant DEFAULT_BOND_ROLE = 1;
    uint8 public constant SWAP_ROUTER_ROLE = 2;
    uint8 public constant BOND_STRATEGY_ROLE = 3;
    uint8 public constant OBOL_MODULE_ROLE = 4;
    uint8 public constant OBOL_STRATEGY_ROLE = 5;

    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address public constant RETH_CHAINLINK_ORACLE =
        0x536218f9E9Eb48863970252233c8F271f554C2d0;
    address public constant STETH_CHAINLINK_ORACLE =
        0x86392dC19c0b719886221c78AB11eb8Cf5c52812;
    address public constant WSTETH_CHAINLINK_ORACLE =
        0x536218f9E9Eb48863970252233c8F271f554C2d0;
    address public constant WETH_CHAINLINK_ORACLE =
        0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

    address public constant WITHDRAWAL_QUEUE =
        0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;
    address public constant DEPOSIT_SECURITY_MODULE =
        0xC77F8768774E1c9244BEed705C4354f2113CFc09;
    address public constant LIDO_LOCATOR =
        0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;
    uint256 public constant SIMPLE_DVT_MODULE_ID = 1;

    bytes32 public constant ATTEST_MESSAGE_PREFIX =
        0xd85557c963041ae93cfa5927261eeb189c486b6d293ccee7da72ca9387cc241d;
    address public constant DEPOSIT_CONTRACT =
        0x00000000219ab540356cBB839Cbe05303d7705Fa;
    address public constant STAKING_ROUTER =
        0xFdDf38947aFB03C621C71b06C9C70bce73f12999;
}
