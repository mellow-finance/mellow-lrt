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

    function testFuzz_SolvencyObol(uint8[] memory actions_) external {
        uint256 maxLength = 1024;
        if (actions_.length > maxLength) {
            assembly {
                mstore(actions_, maxLength)
            }
        }
        Actions[] memory actions = new Actions[](actions_.length);
        for (uint256 i = 0; i < actions_.length; i++) {
            uint256 action = actions_[i] % 5;
            actions[i] = Actions(action);
        }

        runSolvencyTest(actions);
    }

    function testSolvency6() external {
        uint8[182] memory actions_ = [
            124,
            116,
            242,
            220,
            20,
            250,
            198,
            134,
            143,
            125,
            226,
            202,
            29,
            214,
            212,
            186,
            52,
            1,
            167,
            233,
            190,
            83,
            56,
            249,
            9,
            146,
            116,
            245,
            0,
            163,
            34,
            11,
            34,
            114,
            122,
            33,
            68,
            66,
            164,
            196,
            229,
            39,
            84,
            124,
            59,
            154,
            7,
            227,
            104,
            188,
            169,
            173,
            129,
            63,
            14,
            86,
            38,
            240,
            26,
            1,
            163,
            67,
            153,
            24,
            215,
            9,
            5,
            45,
            101,
            225,
            31,
            248,
            95,
            185,
            106,
            175,
            181,
            58,
            207,
            2,
            250,
            145,
            114,
            131,
            29,
            77,
            180,
            209,
            176,
            251,
            50,
            227,
            198,
            87,
            16,
            249,
            194,
            77,
            83,
            17,
            107,
            237,
            189,
            168,
            174,
            28,
            255,
            253,
            124,
            194,
            168,
            224,
            164,
            79,
            166,
            187,
            1,
            124,
            141,
            124,
            33,
            55,
            236,
            31,
            7,
            207,
            211,
            244,
            128,
            176,
            202,
            214,
            127,
            238,
            2,
            205,
            31,
            231,
            175,
            11,
            51,
            224,
            0,
            20,
            65,
            98,
            20,
            132,
            207,
            100,
            179,
            9,
            107,
            20,
            153,
            178,
            251,
            182,
            30,
            52,
            61,
            182,
            16,
            21,
            189,
            139,
            125,
            185,
            122,
            75,
            4,
            255,
            173,
            22,
            2,
            44,
            1,
            1,
            211,
            234,
            11,
            139
        ];
        uint256 maxLength = 1024;
        if (actions_.length > maxLength) {
            assembly {
                mstore(actions_, maxLength)
            }
        }
        Actions[] memory actions = new Actions[](actions_.length);
        for (uint256 i = 0; i < actions_.length; i++) {
            uint256 action = actions_[i] % 5;
            actions[i] = Actions(action);
        }

        runSolvencyTest(actions);
    }
}
