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
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 10_000 ether;

    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant WSTETH_DEFAULT_BOND_FACTORY =
        0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec;
    address public constant WSTETH_DEFAULT_BOND =
        0xC329400492c6ff2438472D4651Ad17389fCb843a;

    address public constant WSTETH_DEFAULT_BOND_FACTORY_TEST =
        0x3F95a719260ce6ec9622bC549c9adCff9edf16D9;
    address public constant WSTETH_DEFAULT_BOND_TEST =
        0xb56da788aa93ed50f50e0d38641519ffb3c3d1eb;
    address public constant MAINNET_TEST_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    uint256 public constant TIMELOCK_PROD_DELAY = 1 days;
    uint256 public constant TIMELOCK_TEST_DELAY = 60 seconds;

    address public constant MELLOW_LIDO_TEST_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant MELLOW_LIDO_TEST_PROXY_MULTISIG =
        0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
    address public constant MELLOW_LIDO_PROD_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant MELLOW_LIDO_PROD_PROXY_MULTISIG =
        0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0;

    address public constant STEAKHOUSE_MULTISIG =
        0x2E93913A796a6C6b2bB76F41690E78a2E206Be54;
    address public constant RE7_MULTISIG =
        0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433;
    address public constant MEV_MULTISIG =
        0xA1E38210B06A05882a7e7Bfe167Cd67F07FA234A;

    // ---------- Ethereum Mainnet (test) ----------

    // Steakhouse:
    string public constant STEAKHOUSE_VAULT_TEST_NAME =
        "Steakhouse Vault (test)";
    string public constant STEAKHOUSE_VAULT_TEST_SYMBOL = "steakLRT (test)";

    // Re7

    string public constant RE7_VAULT_TEST_NAME = "Re7 Labs LRT (test)";
    string public constant RE7_VAULT_TEST_SYMBOL = "Re7LRT (test)";

    // MEV

    string public constant MEV_VAULT_TEST_NAME = "MEVcap ETH (test)";
    string public constant MEV_VAULT_TEST_SYMBOL = "mevcETH (test)";

    // Mellow

    string public constant MELLOW_VAULT_NAME = "Mellow Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mtestETH";
}
