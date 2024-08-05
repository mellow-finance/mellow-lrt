// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../src/Vault.sol";
import "../../src/VaultConfigurator.sol";
import "../../src/validators/AllowAllValidator.sol";
import "../../src/validators/ManagedValidator.sol";
import "../../src/validators/DefaultBondValidator.sol";
import "../../src/validators/ERC20SwapValidator.sol";
import "../../src/utils/DefaultAccessControl.sol";
import "../../src/utils/DepositWrapper.sol";
import "../../src/strategies/SimpleDVTStakingStrategy.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/oracles/ChainlinkOracle.sol";
import "../../src/oracles/ManagedRatiosOracle.sol";
import "../../src/modules/erc20/ERC20TvlModule.sol";
import "../../src/modules/erc20/ERC20SwapModule.sol";
import "../../src/modules/erc20/ManagedTvlModule.sol";
import "../../src/modules/obol/StakingModule.sol";

import "../../src/modules/symbiotic/DefaultBondModule.sol";
import "../../src/modules/symbiotic/DefaultBondTvlModule.sol";

import "../../src/interfaces/external/lido/ISteth.sol";
import "../../src/interfaces/external/lido/IWSteth.sol";
import "../../src/interfaces/external/lido/IStakingRouter.sol";
import "../../src/interfaces/external/lido/IDepositContract.sol";
import "../../src/interfaces/external/uniswap/ISwapRouter.sol";

import "../../src/oracles/WStethRatiosAggregatorV3.sol";
import "../../src/oracles/ConstantAggregatorV3.sol";

import "./Collector.sol";
import "./CurvePoolMock.sol";
import "./CurveCollector.sol";

import "./interfaces/IDefaultCollateralFactory.sol";

library Constants {
    address public constant VAULT_ADMIN =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;

    uint8 public constant OBOL_MODULE_ROLE = 0;
    uint8 public constant OBOL_STRATEGY_ROLE = 1;

    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    address public constant HOLESKY_DEPLOYER =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;
    address public constant DEFAULT_COLLATERAL_FACTORY =
        0x6c8509dbCf264fF1A8F2A9dEEeE5453391B1d2b7;

    address public constant WITHDRAWAL_QUEUE =
        0xc7cc160b58F8Bb0baC94b80847E2CF2800565C50;
    address public constant DEPOSIT_SECURITY_MODULE =
        0x045dd46212A178428c088573A7d102B9d89a022A;
    uint256 public constant SIMPLE_DVT_MODULE_ID = 2;

    uint8 public constant defaultBondStrategyRole = 1;
    uint8 public constant simpleDvtStrategyRole = 2;
    uint8 public constant defaultBondModuleRole = 3;
    uint8 public constant simpleDvtModuleRole = 4;
    uint8 public constant depositRole = 5;

    uint256 public constant Q96 = 2 ** 96;
}
