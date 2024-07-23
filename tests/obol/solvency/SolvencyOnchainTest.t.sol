// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./SolvencyRunner.sol";
import "../Deployments.sol";

contract SolvencyOnchainTest is SolvencyRunner {
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

    function testFuzz_SolvencyObol(
        uint8[] memory actions_,
        uint8 deployIndex
    ) external {
        Deployments.Deployment[] memory deployments = Deployments.deployments();
        if (deployments.length == 0) return;
        Deployments.Deployment memory deployment = deployments[
            deployIndex % deployments.length
        ];
        deployParams = deployment.deployParams;
        setup = deployment.deploySetup;

        cumulative_deposits_weth =
            _tvl_weth(false) -
            deployParams.initialDepositWETH;
        cumulative_processed_withdrawals_weth = 0;

        initial_weth_balance = (_tvl_weth(false) * 99) / 100;
        {
            uint256 total_pending = setup.vault.balanceOf(address(setup.vault));
            uint256 total_supply = setup.vault.totalSupply();
            initial_weth_balance = Math.mulDiv(
                initial_weth_balance,
                total_supply - total_pending,
                total_pending
            );
        }

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
