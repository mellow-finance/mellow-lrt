// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../src/Vault.sol";
import "../../src/VaultConfigurator.sol";
import "../../src/validators/ManagedValidator.sol";
import "../../src/validators/DefaultBondValidator.sol";
import "../../src/validators/ERC20SwapValidator.sol";
import "../../src/utils/DefaultAccessControl.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/oracles/ChainlinkOracle.sol";
import "../../src/oracles/ManagedRatiosOracle.sol";
import "../../src/modules/erc20/ERC20TvlModule.sol";
import "../../src/modules/erc20/ERC20SwapModule.sol";

import "../../src/modules/symbiotic/DefaultBondModule.sol";
import "../../src/modules/symbiotic/DefaultBondTvlModule.sol";

import "../../src/libraries/external/FullMath.sol";

import "../../src/interfaces/external/lido/ISteth.sol";
import "../../src/interfaces/external/lido/IWSteth.sol";
import "../../src/interfaces/external/uniswap/ISwapRouter.sol";

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

    address public constant STETH =
        address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address public constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant WSTETH =
        address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
}
