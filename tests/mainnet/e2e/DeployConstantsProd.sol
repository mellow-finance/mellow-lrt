// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstantsProd {
    // according to https://www.notion.so/mellowprotocol/Contracts-deployment-process-4cd6b91d9aef416291eb510d898f3841?pvs=4#07a01b7b0b7649c28bccd6daea2bcfb9

    // Common constants:

    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    uint256 public constant INITIAL_DEPOSIT_VALUE = 10 ** 10;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 10_000 * 10 ** 18;

    // ---------- Ethereum Mainnet ----------

    // Steakhouse:
    address public constant STEAKHOUSE_LIDO_MELLOW_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant STEAKHOUSE_MELLOW_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant STEAKHOUSE_CURATOR_BOARD_MULTISIG =
        0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
    address public constant STEAKHOUSE_CURATOR_MANAGER =
        0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
    string public constant STEAKHOUSE_VAULT_NAME =
        "Steakhouse Financial Mellow LRT";
    string public constant STEAKHOUSE_VAULT_SYMBOL = "StMLRT";

    // Re7:
    address public constant RE7_LIDO_MELLOW_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant RE7_MELLOW_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant RE7_CURATOR_BOARD_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant RE7_CURATOR_MANAGER =
        0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433;
    string public constant RE7_VAULT_NAME = "Re7 Labs Mellow LRT";
    string public constant RE7_VAULT_SYMBOL = "Re7MLRT";
    
    address public constant RE7_VAULT_INITIALIZER = 0x8f06BEB555D57F0D20dB817FF138671451084e24;
    address payable public constant RE7_VAULT_ADDRESS = payable(0x20eF170856B8A746Df78406bfC2535b36F35774F);
    address payable public constant RE7_VAULT_ADDRESS_INIT = payable(0x20eF170856B8A746Df78406bfC2535b36F35774F);
    address public constant RE7_VAULT_CONFIGURATOR = 0x3492407B9b8e0619d4fF423265F1cA5BE5198dd8;
    address public constant RE7_VAULT_ERC20TVLMODULE = 0xCA60f449867c9101Ec80F8C611eaB39afE7bD638;
    address public constant RE7_VAULT_DEFAULTBONDTVLMODULE = 0x48f758bd51555765EBeD4FD01c85554bD0B3c03B;
    address public constant RE7_VAULT_MANAGED_VALIDATOR = 0xa064e9D2599b7029Bb5d4896812D339ac1aAa111;
    address public constant RE7_VAULT_RATIOS_ORACLE = 0x1437DCcA4e1442f20285Fb7C11805E7a965681e2;
    address public constant RE7_VAULT_PRICE_ORACLE = 0xA5046e9379B168AFA154504Cf16853B6a7728436;
    address public constant RE7_VAULT_DEFAULTBONDMODULE = 0x204043f4bda61F719Ad232b4196E1bc4131a3096;
    address payable public constant RE7_VAULT_DEPOSIT_WRAPPER = payable(0x9d9d932Ff608F505EAd156E79C87A98Eb0527A1c);
    address public constant RE7_VAULT_DEFAULT_PROXY_IMPLEMENTATION = 0x538459eeA06A06018C70bf9794e1c7b298694828;
    address public constant RE7_VAULT_ADMIN_PROXY = 0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
    address public constant RE7_VAULT_RESTRICTING_KEEPER = address(0);
    address public constant RE7_VAULT_WETH_AGGREGATOR = 0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09;
    address public constant RE7_VAULT_WSTETH_AGGREGATOR = 0x773ae8ca45D5701131CA84C58821a39DdAdC709c;
    uint256 public constant RE7_VAULT_WETH_AMOUNT_DEPOSITED = 10000000000;

    
    // P2P:
    address public constant P2P_LIDO_MELLOW_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant P2P_MELLOW_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant P2P_CURATOR_BOARD_MULTISIG =
        0xAbCD790dAFdCD934bCf4C065C9FCe3b82429acD3;
    address public constant P2P_CURATOR_MANAGER =
        0xAbCD790dAFdCD934bCf4C065C9FCe3b82429acD3;
    string public constant P2P_VAULT_NAME = "P2P.org Mellow LRT";
    string public constant P2P_VAULT_SYMBOL = "P2PMLRT";

    // Common Mainnet Constants:
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant MAINNET_DEPLOYER =
        address(bytes20(keccak256("mainnet_deployer"))); // TBA

    // ---------- Holesky Testnet ----------
    // Mellow:
    address public constant HOLESKY_LIDO_MELLOW_MULTISIG =
        0xa0589c7f284c767eCB1954A06B41c4C39B990aFB;
    address public constant HOLESKY_MELLOW_MULTISIG =
        0xC7f3cDE6B27C528F39DD3d3f206f5118Acf99818;
    address public constant HOLESKY_CURATOR_BOARD_MULTISIG =
        0x3998Ae90aA1C6ca0f073e60D38502FA5029008a2;
    address public constant HOLESKY_CURATOR_MANAGER =
        0x3998Ae90aA1C6ca0f073e60D38502FA5029008a2;
}
