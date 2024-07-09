// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    uint256 public constant Q96 = 2 ** 96;

    address public constant HOLESKY_PROXY_VAULT_ADMIN =
        address(bytes20(keccak256("holesky_proxy_vault_admin")));
    address public constant HOLESKY_VAULT_ADMIN =
        address(bytes20(keccak256("holesky_vault_admin")));
    address public constant HOLESKY_CURATOR_ADMIN =
        address(bytes20(keccak256("holesky_curator_admin")));
    address public constant HOLESKY_CURATOR_OPERATOR =
        address(bytes20(keccak256("holesky_curator_operator")));
    address public constant HOLESKY_DEPLOYER =
        address(bytes20(keccak256("holesky_deployer")));

    address public constant MAINNET_PROXY_VAULT_ADMIN =
        address(bytes20(keccak256("mainnet_proxy_vault_admin")));
    address public constant MAINNET_VAULT_ADMIN =
        address(bytes20(keccak256("mainnet_vault_admin")));
    address public constant MAINNET_CURATOR_ADMIN =
        address(bytes20(keccak256("mainnet_curator_admin")));
    address public constant MAINNET_CURATOR_OPERATOR =
        address(bytes20(keccak256("mainnet_curator_operator")));
    address public constant MAINNET_DEPLOYER =
        address(bytes20(keccak256("mainnet_deployer")));

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
    address public constant HOLESKY_LIDO_LOCATOR =
        0x28FAB2059C713A7F9D8c86Db49f9bb0e96Af1ef8;

    address public constant MAINNET_STETH =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant MAINNET_WSTETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant MAINNET_WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant MAINNET_LIDO_LOCATOR =
        0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;

    // ---------- Ethereum Mainnet ----------

    // Mellow
    string public constant MELLOW_VAULT_NAME = "Mellow Obol Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mobETHTest";
}
