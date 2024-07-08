// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    uint256 public constant Q96 = 2 ** 96;

    address public constant PROXY_VAULT_ADMIN =
        0x20daa9d68196aa882A856D0aBBEbB6836Dc4B840;
    address public constant VAULT_ADMIN =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant CURATOR_ADMIN =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant CURATOR_OPERATOR =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant HOLESKY_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public constant WITHDRAWAL_QUEUE =
        0xc7cc160b58F8Bb0baC94b80847E2CF2800565C50;
    address public constant LIDO_LOCATOR =
        0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8;
    uint256 public constant SIMPLE_DVT_MODULE_ID = 2;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DELEGATE_CALLER_ROLE_BIT = 1;
    uint8 public constant VAULT_ROLE = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    uint256 public constant INITIAL_DEPOSIT_ETH = 10 gwei;
    uint256 public constant FIRST_DEPOSIT_ETH = 1 ether;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 10000 ether;

    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    // ---------- Ethereum Mainnet ----------

    // Mellow
    string public constant MELLOW_VAULT_NAME = "Mellow Obol Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mobETHTest";
}
