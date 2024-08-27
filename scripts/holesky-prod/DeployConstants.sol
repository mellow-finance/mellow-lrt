// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    uint256 public constant INITIAL_DEPOSIT_ETH = 10 gwei;
    uint256 public constant FIRST_DEPOSIT_ETH = 1 ether;
    uint256 public constant MAXIMAL_TOTAL_SUPPLY = 10_000 ether; // only for new batch

    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;
    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;

    address public constant WSTETH_DEFAULT_BOND_FACTORY =
        0x7224eeF9f38E9240beA197970367E0A8CBDFDD8B;
    address public constant WSTETH_DEFAULT_BOND =
        0x23E98253F372Ee29910e22986fe75Bb287b011fC;

    address public constant HOLESKY_TEST_DEPLOYER =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;

    address public constant MELLOW_LIDO_MULTISIG =
        0x2C5f98743e4Cb30d8d65e30B8cd748967D7A051e;
    address public constant MELLOW_LIDO_PROXY_MULTISIG =
        0x3995c5a3A74f3B3049fD5DA7C7D7BaB0b581A6e1;
    address public constant MELLOW_CURATOR_MULTISIG =
        0x20daa9d68196aa882A856D0aBBEbB6836Dc4B840;

    // ---------- Ethereum Mainnet ----------

    // Mellow
    string public constant MELLOW_VAULT_NAME = "Mellow Test ETH";
    string public constant MELLOW_VAULT_SYMBOL = "mETH (test)";
}
