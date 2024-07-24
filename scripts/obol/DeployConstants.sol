// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    uint256 public constant Q96 = 2 ** 96;

    address public constant HOLESKY_PROXY_VAULT_ADMIN =
        0x3995c5a3A74f3B3049fD5DA7C7D7BaB0b581A6e1;
    address public constant HOLESKY_VAULT_ADMIN =
        0x2C5f98743e4Cb30d8d65e30B8cd748967D7A051e;
    address public constant HOLESKY_CURATOR_ADMIN =
        0xa9f8D7E123784ED914724B8d11D5e669De5cC4d8;
    address public constant HOLESKY_CURATOR_OPERATOR =
        0x73a5ac225B0b345AE95c45a4bBF5D96Ca6f26810;
    address public constant HOLESKY_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

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
    uint256 public constant MAXIMAL_ALLOWED_REMAINDER = 1 ether;

    address public constant HOLESKY_STETH =
        0x67a8422c5301358e60209d13884090028FD3B294;
    address public constant HOLESKY_WSTETH =
        0xC937e208aCd2Ea6126A3B7731C7c72f6E9307D1b;
    address public constant HOLESKY_WETH =
        0x94373a4919B3240D86eA41593D5eBa789FEF3848;
    address public constant HOLESKY_LIDO_LOCATOR =
        0x68A0457845E2b9754A760EE66eddF3d121251802;

    address public constant MAINNET_STETH =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant MAINNET_WSTETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant MAINNET_WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant MAINNET_LIDO_LOCATOR =
        0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb;

    // ---------- Ethereum Mainnet ----------

    string public constant MELLOW_VAULT_NAME = "Distributed Validator stETH";
    string public constant MELLOW_VAULT_SYMBOL = "DVstETH";
}
