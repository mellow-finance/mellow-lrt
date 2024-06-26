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

    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    address public constant WSTETH_DEFAULT_BOND_FACTORY =
        0x6c8509dbCf264fF1A8F2A9dEEeE5453391B1d2b7;
    address public constant WSTETH_DEFAULT_BOND =
        0x3414C4b9FcB4556287AC9975c3f192D05d855d76;
    address public constant HOLESKY_TEST_DEPLOYER =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;

    uint256 public constant TIMELOCK_PROD_DELAY = 1 days;
    uint256 public constant TIMELOCK_TEST_DELAY = 60 seconds;

    address public constant MELLOW_LIDO_TEST_MULTISIG =
        0x8EB5AEeBaE9339b0178863Ee0182010E39782639;
    address public constant MELLOW_LIDO_TEST_PROXY_MULTISIG =
        0xf9DC2a46014f80eF35C22405656b7E70e65a10bf;

    address public constant STEAKHOUSE_MULTISIG =
        0xD3B1525bC3cf0bEb474e945B7E5705803d24bc16;
    address public constant RE7_MULTISIG =
        0xD3B1525bC3cf0bEb474e945B7E5705803d24bc16;
    address public constant MEV_MULTISIG =
        0xD3B1525bC3cf0bEb474e945B7E5705803d24bc16;

    // ---------- HOLESKY ----------

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
