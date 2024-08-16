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
    uint256 public constant MAXIMAL_TOTAL_SUPPLY_QUASAR = 10000 ether;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY_BEDROCK = 20000 ether;

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

    address public constant MELLOW_WSTETH_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant MELLOW_WSTETH_PROXY_MULTISIG =
        0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0;

    address public constant Quasar_WSTETH_MULTISIG =
        0x013B33aAdae8aBdc7c2B1529BB28a37299D6EadE;
    address public constant Bedrock_MULTISIG =
        0x9275cC6de34471f4a669e9dc0F90994Ad6702DA9;

    // ---------- Ethereum Mainnet ----------

    // Quasar_WSTETH
    string public constant Quasar_VAULT_NAME = "unified restaked LRT";
    string public constant Quasar_VAULT_SYMBOL = "urLRT";

    // Bedrock
    string public constant Bedrock_VAULT_NAME = "Rockmelon ETH";
    string public constant Bedrock_VAULT_SYMBOL = "roETH";

    // Mellow
    string public constant MELLOW_VAULT_NAME = "Mellow Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mETH (test)";
}
