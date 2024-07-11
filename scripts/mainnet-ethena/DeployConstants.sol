// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

library DeployConstants {
    // Common constants:

    uint256 public constant Q96 = 2 ** 96;

    uint8 public constant DEPOSITOR_ROLE_BIT = 0;
    uint8 public constant DEFAULT_BOND_STRATEGY_ROLE_BIT = 1;
    uint8 public constant DEFAULT_BOND_MODULE_ROLE_BIT = 2;
    uint8 public constant ADMIN_ROLE_BIT = 255;

    address public constant ENA = 0x57e114B691Db790C35207b2e685D4A43181e6061;
    uint256 public constant ENA_VAULT_LIMIT = 67_500_000 ether;

    address public constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    uint256 public constant SUSDE_VAULT_LIMIT = 37_500_000 ether;

    uint256 public constant INITIAL_DEPOSIT = 1 gwei;

    address public constant DEFAULT_BOND_FACTORY =
        0x1BC8FCFbE6Aa17e4A7610F51B888f34583D202Ec;
    address public constant ENA_DEFAULT_BOND =
        0xe39B5f5638a209c1A6b6cDFfE5d37F7Ac99fCC84;
    address public constant SUSDE_DEFAULT_BOND =
        0x19d0D8e6294B7a04a2733FE433444704B791939A;

    address public constant MAINNET_DEPLOYER =
        0x188858AC61a74350116d1CB6958fBc509FD6afA1;
    address public constant MAINNET_TEST_DEPLOYER =
        0x5C0F3DE4ba6AD53bb8E27f965170A52671e525Bf;

    address public constant MELLOW_ETHENA_MULTISIG =
        0xa5136542ECF3dCAFbb3bd213Cd7024B4741dBDE6;
    address public constant MELLOW_ETHENA_PROXY_MULTISIG =
        0x27a907d1F809E8c03d806Dc31c8E0C545A3187fC;

    address public constant ETHENA_CURATOR_MEV =
        0x3C5f18FE9d6788bD64c48d083B0A4753E401841E;
    address public constant ETHENA_CURATOR_RE7 =
        0x91e22921Ac9dA6Fb0C04048997bf6029646a0F6f;
    address public constant ETHENA_CURATOR_NEXO =
        0xac56c95dc901869786c6F37CF705822b0E79B6F6;

    // ---------- Ethereum Mainnet ----------

    // Ethena ENA vault
    string public constant ENA_VAULT_NAME = "Ethena LRT Vault ENA";
    string public constant ENA_VAULT_SYMBOL = "rsENA";

    // Ethena sUSDe vault
    string public constant SUSDE_VAULT_NAME = "Ethena LRT Vault sUSDe";
    string public constant SUSDE_VAULT_SYMBOL = "rsUSDe";
}
