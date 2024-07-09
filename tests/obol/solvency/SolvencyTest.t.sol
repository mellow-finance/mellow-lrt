// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./SolvencyRunner.sol";

contract SolvencyTest is SolvencyRunner {
    using SafeERC20 for IERC20;

    SolvencyTestParams public holeskyParams =
        SolvencyTestParams(
            DeployInterfaces.DeployParameters(
                DeployConstants.HOLESKY_DEPLOYER,
                DeployConstants.HOLESKY_PROXY_VAULT_ADMIN,
                DeployConstants.HOLESKY_VAULT_ADMIN,
                DeployConstants.HOLESKY_CURATOR_ADMIN,
                DeployConstants.HOLESKY_CURATOR_OPERATOR,
                DeployConstants.HOLESKY_LIDO_LOCATOR,
                DeployConstants.HOLESKY_WSTETH,
                DeployConstants.HOLESKY_STETH,
                DeployConstants.HOLESKY_WETH,
                DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                DeployConstants.MELLOW_VAULT_NAME,
                DeployConstants.MELLOW_VAULT_SYMBOL,
                DeployConstants.INITIAL_DEPOSIT_ETH,
                DeployConstants.FIRST_DEPOSIT_ETH,
                Vault(payable(address(0))),
                Initializer(address(0)),
                ERC20TvlModule(address(0)),
                StakingModule(address(0)),
                ManagedRatiosOracle(address(0)),
                ChainlinkOracle(address(0)),
                IAggregatorV3(address(0)),
                IAggregatorV3(address(0)),
                DefaultProxyImplementation(address(0))
            ),
            new Actions[](0)
        );

    SolvencyTestParams public mainnetParams =
        SolvencyTestParams(
            DeployInterfaces.DeployParameters(
                DeployConstants.MAINNET_DEPLOYER,
                DeployConstants.MAINNET_PROXY_VAULT_ADMIN,
                DeployConstants.MAINNET_VAULT_ADMIN,
                DeployConstants.MAINNET_CURATOR_ADMIN,
                DeployConstants.MAINNET_CURATOR_OPERATOR,
                DeployConstants.MAINNET_LIDO_LOCATOR,
                DeployConstants.MAINNET_WSTETH,
                DeployConstants.MAINNET_STETH,
                DeployConstants.MAINNET_WETH,
                DeployConstants.MAXIMAL_TOTAL_SUPPLY,
                DeployConstants.MELLOW_VAULT_NAME,
                DeployConstants.MELLOW_VAULT_SYMBOL,
                DeployConstants.INITIAL_DEPOSIT_ETH,
                DeployConstants.FIRST_DEPOSIT_ETH,
                Vault(payable(address(0))),
                Initializer(address(0)),
                ERC20TvlModule(address(0)),
                StakingModule(address(0)),
                ManagedRatiosOracle(address(0)),
                ChainlinkOracle(address(0)),
                IAggregatorV3(address(0)),
                IAggregatorV3(address(0)),
                DefaultProxyImplementation(address(0))
            ),
            new Actions[](0)
        );

    function setUp() external {
        Actions[] memory baseActionsList = new Actions[](4);
        baseActionsList[0] = Actions.DEPOSIT;
        baseActionsList[1] = Actions.CONVERT_AND_DEPOSIT;
        baseActionsList[2] = Actions.REGISTER_WITHDRAWAL;
        baseActionsList[3] = Actions.PROCESS_WITHDRAWALS;
        holeskyParams.actions = baseActionsList;
        mainnetParams.actions = baseActionsList;
    }

    function testSolvencyForChain() external {
        if (block.chainid == 1) {
            runSolvencyTest(mainnetParams);
        } else if (block.chainid == 17000) {
            runSolvencyTest(holeskyParams);
        } else {
            revert("Unsupported chain");
        }
    }
}
