// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library Constants {
    address public constant VAULT_ADMIN =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;

    uint8 public constant OBOL_MODULE_ROLE = 0;
    uint8 public constant OBOL_STRATEGY_ROLE = 1;

    address public constant STETH = 0x3F1c547b21f65e10480dE3ad8E19fAAC46C95034;
    address public constant WSTETH = 0x8d09a4502Cc8Cf1547aD300E066060D043f6982D;
    address public constant WETH = 0x94373a4919B3240D86eA41593D5eBa789FEF3848;

    address public constant HOLESKY_DEPLOYER =
        0x7777775b9E6cE9fbe39568E485f5E20D1b0e04EE;
    address public constant DEFAULT_COLLATERAL_FACTORY =
        0x6c8509dbCf264fF1A8F2A9dEEeE5453391B1d2b7;

    address public constant WITHDRAWAL_QUEUE =
        0xc7cc160b58F8Bb0baC94b80847E2CF2800565C50;
    address public constant DEPOSIT_SECURITY_MODULE =
        0x045dd46212A178428c088573A7d102B9d89a022A;
    uint256 public constant SIMPLE_DVT_MODULE_ID = 2;

    uint8 public constant defaultBondStrategyRole = 1;
    uint8 public constant simpleDvtStrategyRole = 2;
    uint8 public constant defaultBondModuleRole = 3;
    uint8 public constant simpleDvtModuleRole = 4;
    uint8 public constant depositRole = 5;

    uint256 public constant Q96 = 2 ** 96;
}
