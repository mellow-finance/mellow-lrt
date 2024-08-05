// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./SolvencyRunner.sol";
import "../Deployments.sol";

contract SolvencyTest is SolvencyRunner {
    using SafeERC20 for IERC20;

    function setUp() external {
        if (block.chainid == 1) {
            chainSetup = ChainSetup({
                attestMessagePrefix: 0xd85557c963041ae93cfa5927261eeb189c486b6d293ccee7da72ca9387cc241d,
                stakingRouterRole: 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c,
                stakingModuleRole: 0xFE5986E06210aC1eCC1aDCafc0cc7f8D63B3F977
            });
        } else if (block.chainid == 17000) {
            chainSetup = ChainSetup({
                attestMessagePrefix: 0x517f1a256ad7aa76f1fd7f0190e4e8eb0e01e75d9f5cf0d54a747384536765b9,
                stakingRouterRole: 0x5ce994D929eaDb0F287341a0eE74aF3FB5711BBA,
                stakingModuleRole: 0x16eb61328b9dCC48A386075035d6d4aeDee873C9
            });
        }

        deployParams = Deployments.deployParameters();
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
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL, 90);
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
        index = append(actions, index, Actions.LIDO_SUBMIT, 1);
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
        index = append(actions, index, Actions.LIDO_SUBMIT, 1);
        index = append(actions, index, Actions.DEPOSIT, 2);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.PROCESS_WITHDRAWALS);
        index = append(actions, index, Actions.DEPOSIT);
        index = append(actions, index, Actions.CONVERT);
        index = append(actions, index, Actions.DEPOSIT, 2);
        index = append(actions, index, Actions.REGISTER_WITHDRAWAL, 4);
        index = append(actions, index, Actions.DEPOSIT, 10);
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

    function testSolvency6() external {
        Actions[] memory actions = new Actions[](1024);
        uint256 index = 0;

        index = append(actions, index, Actions.LIDO_SUBMIT, 10);
        index = append(actions, index, Actions.TARGET_SHARE_UPDATE);
        for (uint256 i = 0; i < 10; i++) {
            index = append(actions, index, Actions.DEPOSIT);
        }

        index = append(actions, index, Actions.STAKING_MODULE_LIMIT_INCREMENT);
        index = append(actions, index, Actions.CONVERT_AND_DEPOSIT);

        assembly {
            mstore(actions, index)
        }
        runSolvencyTest(actions);
    }

    function testFuzz_SolvencyObol(uint8[] memory actions_) external {
        uint256 maxLength = 64;
        uint256 k = uint256(type(Actions).max) + 1;
        require(k ** 2 <= 2 ** 8, "Invalid type");
        Actions[] memory actions = new Actions[](actions_.length * 2);
        for (uint256 i = 0; i < actions.length; i += 2) {
            actions[i] = Actions(actions_[i >> 1] % k);
            actions[i + 1] = Actions((actions_[i >> 1] / k) % k);
        }
        if (actions.length > maxLength) {
            assembly {
                mstore(actions, maxLength)
            }
        }
        runSolvencyTest(actions);
    }
}
