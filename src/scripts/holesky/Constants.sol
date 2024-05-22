// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../Vault.sol";
import "../../VaultConfigurator.sol";
import "../../validators/AllowAllValidator.sol";
import "../../validators/ManagedValidator.sol";
import "../../validators/DefaultBondValidator.sol";
import "../../validators/ERC20SwapValidator.sol";
import "../../utils/DefaultAccessControl.sol";
import "../../utils/DepositWrapper.sol";
import "../../strategies/SimpleDVTStakingStrategy.sol";
import "../../strategies/DefaultBondStrategy.sol";
import "../../oracles/ChainlinkOracle.sol";
import "../../oracles/ManagedRatiosOracle.sol";
import "../../modules/erc20/ERC20TvlModule.sol";
import "../../modules/erc20/ERC20SwapModule.sol";
import "../../modules/erc20/ManagedTvlModule.sol";
import "../../modules/obol/StakingModule.sol";

import "../../modules/symbiotic/DefaultBondModule.sol";
import "../../modules/symbiotic/DefaultBondTvlModule.sol";

import "../../libraries/external/FullMath.sol";

import "../../interfaces/external/lido/ISteth.sol";
import "../../interfaces/external/lido/IWSteth.sol";
import "../../interfaces/external/lido/IStakingRouter.sol";
import "../../interfaces/external/lido/IDepositContract.sol";
import "../../interfaces/external/uniswap/ISwapRouter.sol";

import "./mocks/WStethRatiosAggregatorV3.sol";
import "./mocks/ConstantAggregatorV3.sol";

library Constants {
    address public constant VAULT_ADMIN =
        address(bytes20(keccak256("VAULT_ADMIN")));
    address public constant VAULT_OPERATOR =
        address(bytes20(keccak256("VAULT_OPERATOR")));
    address public constant DEPOSITOR =
        address(bytes20(keccak256("DEPOSITOR")));

    uint8 public constant OBOL_MODULE_ROLE = 0;
    uint8 public constant OBOL_STRATEGY_ROLE = 1;

    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    address public constant WITHDRAWAL_QUEUE =
        0xc7cc160b58F8Bb0baC94b80847E2CF2800565C50;
    address public constant DEPOSIT_SECURITY_MODULE =
        0x045dd46212A178428c088573A7d102B9d89a022A;
    uint256 public constant SIMPLE_DVT_MODULE_ID = 1;
}
