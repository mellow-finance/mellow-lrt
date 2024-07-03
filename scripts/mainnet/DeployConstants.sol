// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    // according to https://www.notion.so/mellowprotocol/Contracts-deployment-4cd6b91d9aef416291eb510d898f3841?pvs=4#07a01b7b0b7649c28bccd6daea2bcfb9
    // Common constants:

    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    uint256 public constant INITIAL_DEPOSIT_ETH = 10 gwei;
    uint256 public constant FIRST_DEPOSIT_ETH = 1 ether;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 1 ether; // only for new batch

    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant WSTETH_DEFAULT_BOND_FACTORY =
        0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec;
    address public constant WSTETH_DEFAULT_BOND =
        0xC329400492c6ff2438472D4651Ad17389fCb843a;

    address public constant MAINNET_DEPLOYER =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant MAINNET_TEST_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    address public constant MELLOW_LIDO_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant MELLOW_LIDO_PROXY_MULTISIG =
        0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0;

    //  batch 1
    address public constant STEAKHOUSE_MULTISIG =
        0x2afc096981c2CFe3501bE4054160048718F6C0C8;
    address public constant RE7_MULTISIG =
        0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433;
    address public constant AMPHOR_MULTISIG =
        0xA1E38210B06A05882a7e7Bfe167Cd67F07FA234A;
    address public constant P2P_MULTISIG =
        0x4a3c7F2470Aa00ebE6aE7cB1fAF95964b9de1eF4;

    // batch 2
    address public constant INFSTONES_MULTISIG =
        0xD3895c43E886778e7e1E099c280a8c5Aa5B2a4D8;
    address public constant RENZO_MULTISIG =
        0x6e5CaD73D00Bc8340f38afb61Fc5E34f7193F599;
    address public constant CHORUS_ONE_MULTISIG =
        0x3Ea145D6Cea2e939d866bA71136dca6a1B96919f;
    address public constant LUGANODES_MULTISIG =
        0x1FBBc71B60A499c09D454725AcF1d6931515671A;

    // ---------- Ethereum Mainnet ----------

    // Steakhouse
    string public constant STEAKHOUSE_VAULT_NAME =
        "Steakhouse Resteaking Vault";
    string public constant STEAKHOUSE_VAULT_SYMBOL = "steakLRT";

    // Re7
    string public constant RE7_VAULT_NAME = "Re7 Labs LRT";
    string public constant RE7_VAULT_SYMBOL = "Re7LRT";

    // Amphor
    string public constant AMPHOR_VAULT_NAME = "Amphor Restaked ETH";
    string public constant AMPHOR_VAULT_SYMBOL = "amphrETH";

    // P2P
    string public constant P2P_VAULT_NAME = "Restaking Vault ETH";
    string public constant P2P_VAULT_SYMBOL = "rstETH";

    // Mellow
    string public constant MELLOW_VAULT_NAME = "Mellow Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mETH (test)";

    // Infstones
    string public constant INFSTONES_VAULT_NAME = "InfStones Restaked ETH";
    string public constant INFSTONES_VAULT_SYMBOL = "ifsETH";

    // Renzo
    string public constant RENZO_VAULT_NAME = "Renzo Restaked LST ";
    string public constant RENZO_VAULT_SYMBOL = "pzETH";

    // Chorus one
    string public constant CHORUS_ONE_VAULT_NAME =
        "Chorus One Restaking Vault ETH";
    string public constant CHORUS_ONE_VAULT_SYMBOL = "coETH";

    // Luganodes
    string public constant LUGANODES_VAULT_NAME = "LugaETH";
    string public constant LUGANODES_VAULT_SYMBOL = "LugaETH";
}
