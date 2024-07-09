// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    uint256 public constant Q96 = 2 ** 96;

    address public constant HOLESKY_PROXY_VAULT_ADMIN =
        0x20daa9d68196aa882A856D0aBBEbB6836Dc4B840;
    address public constant HOLESKY_VAULT_ADMIN =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant HOLESKY_CURATOR_ADMIN =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant HOLESKY_CURATOR_OPERATOR =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant HOLESKY_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;
    address public constant HOLESKY_LIDO_LOCATOR =
        0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8;

    address public constant MAINNET_PROXY_VAULT_ADMIN =
        0x81698f87C6482bF1ce9bFcfC0F103C4A0Adf0Af0;
    address public constant MAINNET_VAULT_ADMIN =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant MAINNET_CURATOR_ADMIN =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant MAINNET_CURATOR_OPERATOR =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant MAINNET_DEPLOYER =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant MAINNET_LIDO_LOCATOR =
        0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;

    uint256 public constant SIMPLE_DVT_MODULE_ID = 2;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DELEGATE_CALLER_ROLE_BIT = 1;
    uint8 public constant VAULT_ROLE = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    uint256 public constant INITIAL_DEPOSIT_ETH = 10 gwei;
    uint256 public constant FIRST_DEPOSIT_ETH = 1 ether;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 10000 ether;

    address public constant HOLESKY_STETH =
        0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant HOLESKY_WSTETH =
        0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant HOLESKY_WETH =
        0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    address public constant MAINNET_STETH =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant MAINNET_WSTETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant MAINNET_WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // ---------- Ethereum Mainnet ----------

    // Mellow
    string public constant MELLOW_VAULT_NAME = "Mellow Obol Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mobETHTest";
}
