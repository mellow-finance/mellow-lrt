// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    // according to https://www.notion.so/mellowprotocol/Contracts-deployment-process-4cd6b91d9aef416291eb510d898f3841?pvs=4#07a01b7b0b7649c28bccd6daea2bcfb9

    // Common constants:

    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    uint256 public constant INITIAL_DEPOSIT_VALUE = 10 ** 10;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 10_000 * 10 ** 18;

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
    address public constant HOLESKY_DEPLOYER =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;

    string public constant HOLESKY_VAULT_NAME = "Holesky Mellow LRT";
    string public constant HOLESKY_VAULT_SYMBOL = "HMLRT";

    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    address public constant WSTETH_DEFAULT_BOND =
        0x3414C4b9FcB4556287AC9975c3f192D05d855d76;
}
