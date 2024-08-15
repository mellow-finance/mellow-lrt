// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    // Common constants:

    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    address public constant TBTC = 0x18084fbA666a33d37592fA2633fD49a74DD93a88;
    uint256 public constant TBTC_VAULT_LIMIT = 100 ether; // 100 btc

    uint256 public constant INITIAL_DEPOSIT = 10 gwei;

    address public constant DEFAULT_BOND_FACTORY =
        0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec;
    address public constant TBTC_DEFAULT_BOND =
        0x0C969ceC0729487d264716e55F232B404299032c;

    address public constant MAINNET_DEPLOYER =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant MAINNET_TEST_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;


    address public constant MELLOW_TBTC_PROXY_MULTISIG = 0x002910769444bd0D715CC4c6f2A90D92C5e6695e; // TODO
    address public constant MELLOW_TBTC_MULTISIG = 0x6aD30f260c5081Cae68962e2f1730a3727987Deb; // TODO


    address public constant Re7_TBTC_MULTISIG =
        0xE86399fE6d7007FdEcb08A2ee1434Ee677a04433;

    // ---------- Ethereum Mainnet ----------

    // Re7 tBTC
    string public constant Re7_TBTC_VAULT_NAME = "Re7 Labs Restaked tBTC";
    string public constant Re7_TBTC_VAULT_SYMBOL = "Re7rtBTC";
}
