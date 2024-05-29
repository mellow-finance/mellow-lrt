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

    // ---------- Ethereum Mainnet ----------

    // Steakhouse:
    address public constant STEAKHOUSE_LIDO_MELLOW_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant STEAKHOUSE_MELLOW_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant STEAKHOUSE_CURATOR_BOARD_MULTISIG =
        0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
    address public constant STEAKHOUSE_CURATOR_MANAGER =
        0xD8996bb6e74b82Ca4DA473A7e4DD4A1974AFE3be;
    uint256 public constant STEAKHOUSE_INITIAL_DEPOSIT_VALUE = 10 ** 10;
    uint256 public constant STEAKHOUSE_MAXIMAL_TOTAL_SUPPLY = 10_000 * 10 ** 18;

    // Re7:
    address public constant RE7_LIDO_MELLOW_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant RE7_MELLOW_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant RE7_CURATOR_BOARD_MULTISIG =
        0xf364d670F152b8764C8b7ab0d8d1531803FF3D83;
    address public constant RE7_CURATOR_MANAGER =
        0xf364d670F152b8764C8b7ab0d8d1531803FF3D83;
    uint256 public constant RE7_INITIAL_DEPOSIT_VALUE = 10 ** 10;
    uint256 public constant RE7_MAXIMAL_TOTAL_SUPPLY = 10_000 * 10 ** 18;

    // P2P:
    address public constant P2P_LIDO_MELLOW_MULTISIG =
        0x9437B2a8cF3b69D782a61f9814baAbc172f72003;
    address public constant P2P_MELLOW_MULTISIG =
        0x4573ed3B7bFc6c28a5c7C5dF0E292148e3448Fd6;
    address public constant P2P_CURATOR_BOARD_MULTISIG =
        0xAbCD790dAFdCD934bCf4C065C9FCe3b82429acD3;
    address public constant P2P_CURATOR_MANAGER =
        0xAbCD790dAFdCD934bCf4C065C9FCe3b82429acD3;
    uint256 public constant P2P_INITIAL_DEPOSIT_VALUE = 10 ** 10;
    uint256 public constant P2P_MAXIMAL_TOTAL_SUPPLY = 10_000 * 10 ** 18;

    // Common Mainnet Constants:
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant MAINNET_DEPLOYER =
        address(bytes20(keccak256("mainnet_deployer"))); // TBA

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
    uint256 public constant HOLESKY_INITIAL_DEPOSIT_VALUE = 10 ** 10;
    uint256 public constant HOLESKY_MAXIMAL_TOTAL_SUPPLY = 10_000 * 10 ** 18;
}
