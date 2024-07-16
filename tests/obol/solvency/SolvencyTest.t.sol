// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./SolvencyRunner.sol";

contract SolvencyTest is SolvencyRunner {
    using SafeERC20 for IERC20;

    DeployInterfaces.DeployParameters private holeskyParams =
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
            DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
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
        );

    DeployInterfaces.DeployParameters private mainnetParams =
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
            DeployConstants.MAXIMAL_ALLOWED_REMAINDER,
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
        );

    function setUp() external {
        if (block.chainid == 1) {
            deployParams = mainnetParams;
        } else if (block.chainid == 17000) {
            deployParams = holeskyParams;
        } else {
            revert("Unsupported chain");
        }

        deal(
            deployParams.weth,
            deployParams.deployer,
            deployParams.initialDepositWETH
        );

        vm.startPrank(deployParams.deployer);
        deployParams = commonContractsDeploy(deployParams);
        (deployParams, setup) = deploy(deployParams);
        vm.stopPrank();
    }

    function append(
        Actions[] memory actions,
        uint256 index,
        Actions new_action,
        uint256 cnt
    ) internal pure returns (uint256) {
        require(index + cnt < actions.length, "Too many actions to append");
        for (uint256 i = 0; i < cnt; i++) actions[index++] = new_action;
        return index;
    }

    function append(
        Actions[] memory actions,
        uint256 index,
        Actions new_action
    ) internal pure returns (uint256) {
        return append(actions, index, new_action, 1);
    }

    function testSolvency1() external {
        Actions[] memory actions = new Actions[](1024);
        uint256 index = 0;
        index = append(actions, index, Actions.DEPOSIT, 50);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL, 40);
        index = append(actions, index, Actions.PROCESS_WITHDRAWALS, 50);
        index = append(actions, index, Actions.DEPOSIT, 50);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL, 50);
        index = append(actions, index, Actions.CONVERT, 1);
        index = append(actions, index, Actions.DEPOSIT, 50);
        assembly {
            mstore(actions, index)
        }
        runSolvencyTest(actions);
    }

    function testSolvency2() external {
        Actions[] memory actions = new Actions[](1024);
        uint256 index = 0;
        index = append(actions, index, Actions.DEPOSIT, 200);
        assembly {
            mstore(actions, index)
        }
        runSolvencyTest(actions);
    }

    function testSolvency3() external {
        Actions[] memory actions = new Actions[](1024);
        uint256 index = 0;
        index = append(actions, index, Actions.DEPOSIT, 200);
        index = append(actions, index, Actions.CONVERT_AND_DEPOSIT);
        assembly {
            mstore(actions, index)
        }
        runSolvencyTest(actions);
    }

    function testSolvency4() external {
        Actions[] memory actions = new Actions[](1024);
        uint256 index = 0;
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.PROCESS_WITHDRAWALS);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.CONVERT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL);
        index = append(actions, index, Actions.PROCESS_WITHDRAWALS);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.CONVERT_AND_DEPOSIT);
        assembly {
            mstore(actions, index)
        }
        runSolvencyTest(actions);
    }

    function testSolvency5() external {
        Actions[] memory actions = new Actions[](1024);
        uint256 index = 0;
        index = append(actions, index, Actions.DEPOSIT, 10);
        index = append(actions, index, Actions.CONVERT_AND_DEPOSIT);
        assembly {
            mstore(actions, index)
        }
        runSolvencyTest(actions);
    }
}
