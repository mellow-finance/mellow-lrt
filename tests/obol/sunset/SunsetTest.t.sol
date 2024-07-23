// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../solvency/SolvencyRunner.sol";
import "../Deployments.sol";

contract SunsetTest is SolvencyRunner {
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

    function prepare() internal {
        set_inf_stake_limit();
        set_inf_dsm_max_deposits();
        set_vault_limit(1e9 ether);
        add_initial_depositors();

        uint256 batches = 10;
        uint256 countPerBatch = 10;
        uint256 increaseLimitsCount = 5;

        for (uint256 batchIndex = 0; batchIndex < batches; batchIndex++) {
            transition_external_submit();

            for (uint256 i = 0; i < countPerBatch; i++) {
                transition_random_deposit();
            }
            for (uint256 i = 0; i < countPerBatch; i++) {
                transition_request_random_withdrawal();
            }
        }

        for (uint256 i = 0; i < increaseLimitsCount; i++) {
            transition_staking_module_limit_increment();
        }

        transition_convert_and_deposit();
    }

    function testSunset() external {
        // creating multiple deposits + withdrawal requests
        prepare();

        // processing them all
        finalize_test();

        // validation process
        validate_invariants();
        validate_final_invariants();
    }
}
