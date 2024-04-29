// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../src/Vault.sol";
import "../../src/ProtocolGovernance.sol";
import "../../src/validators/ManagedValidator.sol";
import "../../src/validators/SymbioticBondValidator.sol";
import "../../src/utils/DefaultAccessControl.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/oracles/ChainlinkOracle.sol";
import "../../src/oracles/ManagedRatiosOracle.sol";
import "../../src/modules/deposit/symbiotic/DefaultBondDepositModule.sol";
import "../../src/modules/tvl/erc20/ERC20TvlModule.sol";
import "../../src/modules/tvl/symbiotic/SymbioticBondTvlModule.sol";
import "../../src/modules/withdraw/symbiotic/DefaultBondWithdrawalModule.sol";

import "../../src/libraries/external/FullMath.sol";

import "../../src/interfaces/external/lido/ISteth.sol";

library Constants {
    address public constant VAULT_ADMIN =
        address(bytes20(keccak256("VAULT_ADMIN")));
    address public constant PROTOCOL_GOVERNANCE_ADMIN =
        address(bytes20(keccak256("PROTOCOL_GOVERNANCE_ADMIN")));
    address public constant DEPOSITOR =
        address(bytes20(keccak256("DEPOSITOR")));

    address public constant STETH =
        address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
}
