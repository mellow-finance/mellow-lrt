// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    // Common constants:

    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    uint256 public constant WBTC_VAULT_LIMIT = 500 ether; // 500 btc
    uint256 public constant INITIAL_DEPOSIT_MULITPLIER = 1e10; // 1e18 (eth) / 1e8 (wbtc)

    address public constant WBTC_DEFAULT_BOND = 0x971e5b5D4baa5607863f3748FeBf287C7bf82618;
    uint256 public constant INITIAL_DEPOSIT = 1000 wei;
    address public constant DEFAULT_BOND_FACTORY = 0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec;

    address public constant MAINNET_DEPLOYER =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;

    address public constant MEV_WBTC_CURATOR = 0xA1E38210B06A05882a7e7Bfe167Cd67F07FA234A;

    address public constant MELLOW_WBTC_PROXY_MULTISIG = 0x002910769444bd0D715CC4c6f2A90D92C5e6695e; // TODO
    address public constant MELLOW_WBTC_MULTISIG = 0x6aD30f260c5081Cae68962e2f1730a3727987Deb; // TODO

    // ---------- Ethereum Mainnet ----------

    // MEV wBTC vault
    string public constant MEV_WBTC_VAULT_NAME = "amphor restaked BTC";
    string public constant MEV_WBTC_VAULT_SYMBOL = "amphrBTC";

}
