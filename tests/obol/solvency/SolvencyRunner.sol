// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/obol/Deploy.s.sol";

contract SolvencyRunner is Test, DeployScript {
    using SafeERC20 for IERC20;

    enum Actions {
        DEPOSIT,
        REGISTER_WITHDRAWAL,
        PROCESS_WITHDRAWALS,
        CONVERT_AND_DEPOSIT,
        CONVERT,
        IDLE_ETHER_CHANGE,
        WSTETH_PRICE_CHANGE
    }

    DeployInterfaces.DeployParameters internal deployParams;
    DeployInterfaces.DeploySetup internal setup;

    uint256 internal constant MAX_ERROR = 10 wei;
    uint256 internal constant Q96 = 2 ** 96;
    uint256 internal constant D18 = 1e18;

    address[] internal depositors;
    uint256[] internal depositedAmounts;
    uint256[] internal withdrawnAmounts;

    uint256 internal cumulative_deposits_weth;
    uint256 internal cumulative_processed_withdrawals_weth;

    function _indexOf(address user) internal view returns (uint256) {
        for (uint256 i = 0; i < depositors.length; i++) {
            if (depositors[i] == user) {
                return i;
            }
        }
        return type(uint256).max;
    }

    uint256 private _seed;

    function _random() internal returns (uint256) {
        _seed = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, _seed)
            )
        );
        return _seed;
    }

    function _randInt(uint256 maxValue) internal returns (uint256) {
        return _random() % (maxValue + 1);
    }

    function _randInt(
        uint256 minValue,
        uint256 maxValue
    ) internal returns (uint256) {
        return (_random() % (maxValue - minValue + 1)) + minValue;
    }

    function random_float_x96(
        uint256 minValue,
        uint256 maxValue
    ) internal returns (uint256) {
        return _randInt(minValue * Q96, maxValue * Q96);
    }

    function random_bool() internal returns (bool) {
        return _random() & 1 == 1;
    }

    function random_address() internal returns (address) {
        return address(uint160(_random()));
    }

    function calc_random_amount_d18() internal returns (uint256 result) {
        uint256 result_x96 = random_float_x96(D18, 10 * D18);
        if (random_bool()) {
            uint256 b_x96 = random_float_x96(1e0, 1e6);
            result = Math.mulDiv(result_x96, b_x96, Q96) / Q96;
            assertLe(1 ether, result, "amount overflow");
        } else {
            uint256 b_x96 = random_float_x96(1e1, 1e10);
            result = Math.mulDiv(result_x96, Q96, b_x96) / Q96;
            assertGe(1 ether, result, "amount underflow");
        }
    }

    function set_vault_limit(uint256 limit) internal {
        vm.startPrank(deployParams.admin);
        setup.configurator.stageMaximalTotalSupply(limit);
        skip(setup.configurator.maximalTotalSupplyDelay());
        setup.configurator.commitMaximalTotalSupply();
        vm.stopPrank();
    }

    function _tvl_weth(bool isRoundingUp) internal view returns (uint256) {
        uint256 weth_locked_amount = IERC20(deployParams.weth).balanceOf(
            address(setup.vault)
        );
        uint256 wsteth_locked_amount = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );

        return
            weth_locked_amount +
            _convert_wsteth_to_weth(wsteth_locked_amount, isRoundingUp);
    }

    function _convert_wsteth_to_weth(
        uint256 amount,
        bool isRoundingUp
    ) internal view returns (uint256) {
        uint256 priceX96 = deployParams.priceOracle.priceX96(
            address(setup.vault),
            deployParams.wsteth
        );
        return
            Math.mulDiv(
                priceX96,
                amount,
                Q96,
                isRoundingUp ? Math.Rounding.Ceil : Math.Rounding.Floor
            );
    }

    function _convert_weth_to_wsteth(
        uint256 amount,
        bool isRoundingUp
    ) internal view returns (uint256) {
        uint256 priceX96 = deployParams.priceOracle.priceX96(
            address(setup.vault),
            deployParams.wsteth
        );
        return
            Math.mulDiv(
                Q96,
                amount,
                priceX96,
                isRoundingUp ? Math.Rounding.Ceil : Math.Rounding.Floor
            );
    }

    function transition_random_deposit() internal {
        address user;
        if (depositors.length == 0 || random_bool()) {
            user = random_address();
            depositors.push(user);
            depositedAmounts.push(0);
            withdrawnAmounts.push(0);
        } else {
            user = depositors[_randInt(0, depositors.length - 1)];
        }
        uint256 amount = calc_random_amount_d18();
        deal(deployParams.weth, user, amount);
        vm.startPrank(user);
        IERC20(deployParams.weth).safeIncreaseAllowance(
            address(setup.vault),
            amount
        );

        uint256 totalSupply = setup.vault.totalSupply();
        uint256 depositValue = amount;
        uint256 totalValue = _tvl_weth(true);
        uint256 expectedLpAmount = Math.mulDiv(
            depositValue,
            totalSupply,
            totalValue
        );

        uint256 wethIndex = deployParams.weth < deployParams.wsteth ? 0 : 1;
        uint256[] memory amounts = new uint256[](2);
        amounts[wethIndex] = amount;

        uint256 lpAmount;
        try
            setup.vault.deposit(user, amounts, 0, type(uint256).max, 0)
        returns (uint256[] memory, uint256 lpAmount_) {
            lpAmount = lpAmount_;
        } catch (bytes memory response) {
            // cannot deposit due to vault maximal total supply overflow
            assertEq(
                bytes4(response),
                bytes4(abi.encodeWithSignature("LimitOverflow()"))
            );
            vm.stopPrank();
            return;
        }
        vm.stopPrank();

        assertEq(expectedLpAmount, lpAmount, "invalid deposit ratio");

        cumulative_deposits_weth += amount;
        depositedAmounts[_indexOf(user)] += amount;
    }

    function transition_random_wsteth_price_change() internal {
        uint256 factor_x96;
        if (random_bool()) {
            factor_x96 = random_float_x96(0.99 ether, 0.99999 ether);
        } else {
            factor_x96 = random_float_x96(1.00001 ether, 1.01 ether);
        }
        factor_x96 = factor_x96 / D18;
        bytes32 slot = keccak256("lido.StETH.totalShares");
        bytes32 current_value = vm.load(deployParams.steth, slot);
        uint256 new_value = Math.mulDiv(
            uint256(current_value),
            Q96,
            factor_x96
        );
        uint256 price_before = IWSteth(deployParams.wsteth).getStETHByWstETH(
            1 ether
        );
        vm.store(deployParams.steth, slot, bytes32(new_value));
        uint256 price_after = IWSteth(deployParams.wsteth).getStETHByWstETH(
            1 ether
        );
        assertApproxEqAbs(
            Math.mulDiv(price_before, factor_x96, Q96),
            price_after,
            1 wei,
            "invalid wsteth price after change"
        );
    }

    function transition_request_random_withdrawal() internal {
        uint256 nonZeroBalances = 0;
        address[] memory depositors_ = depositors;
        uint256[] memory balances = new uint256[](depositors_.length);
        Vault vault = setup.vault;
        address[] memory pendingWithdrawers = vault.pendingWithdrawers();

        for (uint256 i = 0; i < depositors_.length; i++) {
            uint256 amount = vault.balanceOf(depositors_[i]);
            if (amount != 0) {
                nonZeroBalances++;
                balances[i] =
                    amount +
                    vault.withdrawalRequest(depositors_[i]).lpAmount;
                continue;
            }
            for (uint256 j = 0; j < pendingWithdrawers.length; j++) {
                if (pendingWithdrawers[j] == depositors_[i]) {
                    balances[i] = vault
                        .withdrawalRequest(depositors_[i])
                        .lpAmount;
                    nonZeroBalances++;
                    break;
                }
            }
        }
        if (nonZeroBalances == 0) {
            // nothing to withdraw
            return;
        }
        address user;
        uint256 userIndex = 0;
        uint256 nonZeroUserIndex = _randInt(0, nonZeroBalances - 1);
        uint256 lpAmount;
        for (uint256 i = 0; i < depositors_.length; i++) {
            if (balances[i] == 0) continue;
            if (nonZeroUserIndex == userIndex) {
                user = depositors_[i];
                lpAmount = balances[i];
                break;
            }
            userIndex++;
        }

        if (random_bool()) {
            uint256 coefficient_x96 = random_float_x96(0, 1);
            lpAmount = Math.mulDiv(lpAmount, coefficient_x96, D18);
        }
        if (lpAmount == 0) {
            // nothing to withdraw
            return;
        }
        vm.startPrank(user);
        vault.registerWithdrawal(
            user,
            lpAmount,
            new uint256[](2),
            type(uint256).max,
            type(uint256).max,
            true // just in case - close previous withdrawal request
        );
        vm.stopPrank();
    }

    function transition_process_random_requested_withdrawals_subset() internal {
        address[] memory withdrawers = setup.vault.pendingWithdrawers();
        if (withdrawers.length == 0) {
            // nothing to process
            return;
        }

        uint256 numberOfWithdrawals = _randInt(0, withdrawers.length - 1);
        // random shuffle
        for (uint256 i = 1; i < withdrawers.length; i++) {
            uint256 j = _randInt(0, i);
            (withdrawers[i], withdrawers[j]) = (withdrawers[j], withdrawers[i]);
        }

        assembly {
            mstore(withdrawers, numberOfWithdrawals)
        }

        uint256 full_vault_balance_before_processing = _tvl_weth(true);
        uint256[] memory balances = new uint256[](withdrawers.length);

        uint256 total_supply = setup.vault.totalSupply();
        uint256 wsteth_tvl = _convert_weth_to_wsteth(_tvl_weth(false), false);
        uint256[] memory expected_wsteth_amounts = new uint256[](
            withdrawers.length
        );

        for (uint256 i = 0; i < withdrawers.length; i++) {
            balances[i] = IERC20(deployParams.wsteth).balanceOf(withdrawers[i]);
            expected_wsteth_amounts[i] = Math.mulDiv(
                wsteth_tvl,
                setup.vault.withdrawalRequest(withdrawers[i]).lpAmount,
                total_supply
            );
        }

        if (random_bool()) {
            // do not swap weth->wsteth.
            // withdrawal will occur only for prefix of withdrawers that have less total wsteth required
            // than total wsteth on the vault balance

            uint256 total_wsteth_balance = IERC20(deployParams.wsteth)
                .balanceOf(address(setup.vault));

            vm.prank(deployParams.curatorOperator);
            setup.strategy.processWithdrawals(withdrawers, 0);

            for (uint256 i = 0; i < withdrawers.length; i++) {
                uint256 actual_withdrawn_amount = IERC20(deployParams.wsteth)
                    .balanceOf(withdrawers[i]) - balances[i];
                if (actual_withdrawn_amount == 0) {
                    assertLe(
                        total_wsteth_balance,
                        expected_wsteth_amounts[i] + 1 wei,
                        "total_wsteth_balance > expected_wsteth_amount"
                    );
                    assertNotEq(
                        setup.vault.withdrawalRequest(withdrawers[i]).lpAmount,
                        0,
                        "non-zero lpAmount"
                    );
                } else {
                    assertApproxEqAbs(
                        actual_withdrawn_amount,
                        expected_wsteth_amounts[i],
                        1 wei,
                        "invalid expected_wsteth_amount/actual_withdrawn_amount"
                    );
                    assertLe(
                        actual_withdrawn_amount,
                        total_wsteth_balance,
                        "actual_withdrawn_amount > total_wsteth_balance"
                    );
                    total_wsteth_balance -= actual_withdrawn_amount;
                }
            }
        } else {
            bool[] memory expected_processed_withdrawals = new bool[](
                withdrawers.length
            );

            uint256 total_wsteth_balance = IERC20(deployParams.wsteth)
                .balanceOf(address(setup.vault));
            // swap weth to wsteth
            {
                uint256 wsteth_required = 0;
                for (
                    uint256 i = 0;
                    i < expected_processed_withdrawals.length;
                    i++
                ) {
                    expected_processed_withdrawals[i] = random_bool();
                    wsteth_required += expected_processed_withdrawals[i]
                        ? expected_wsteth_amounts[i] +
                            1 wei /* for rounding errors */
                        : 0;
                }

                total_wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
                    address(setup.vault)
                );

                wsteth_required = wsteth_required > total_wsteth_balance
                    ? wsteth_required - total_wsteth_balance
                    : 0;
                uint256 weth_required = _convert_wsteth_to_weth(
                    wsteth_required,
                    true
                );

                if (weth_required != 0) {
                    vm.startPrank(deployParams.curatorAdmin);
                    setup.vault.delegateCall(
                        address(deployParams.stakingModule),
                        abi.encodeWithSelector(
                            StakingModule.convert.selector,
                            weth_required
                        )
                    );
                    vm.stopPrank();
                }
                uint256 new_wsteth_balance = IERC20(deployParams.wsteth)
                    .balanceOf(address(setup.vault));

                assertApproxEqAbs(
                    new_wsteth_balance,
                    total_wsteth_balance +
                        _convert_weth_to_wsteth(weth_required, false),
                    1 wei,
                    "invalid wsteth balance after conversion"
                );

                total_wsteth_balance = new_wsteth_balance;
            }

            vm.prank(deployParams.curatorOperator);
            setup.strategy.processWithdrawals(withdrawers, 0);

            for (uint256 i = 0; i < withdrawers.length; i++) {
                uint256 actual_withdrawn_amount = IERC20(deployParams.wsteth)
                    .balanceOf(withdrawers[i]) - balances[i];
                if (actual_withdrawn_amount == 0) {
                    assertFalse(
                        expected_processed_withdrawals[i],
                        "unexpected withdrawal"
                    );
                    assertLe(
                        total_wsteth_balance,
                        expected_wsteth_amounts[i] + 1 wei,
                        "total_wsteth_balance > expected_wsteth_amount"
                    );
                    assertNotEq(
                        setup.vault.withdrawalRequest(withdrawers[i]).lpAmount,
                        0,
                        "non-zero lpAmount"
                    );
                } else {
                    assertTrue(
                        expected_processed_withdrawals[i],
                        "withdrawal not processed"
                    );
                    assertApproxEqAbs(
                        actual_withdrawn_amount,
                        expected_wsteth_amounts[i],
                        1 wei,
                        "invalid expected_wsteth_amount/actual_withdrawn_amount"
                    );
                    assertLe(
                        actual_withdrawn_amount,
                        total_wsteth_balance,
                        "actual_withdrawn_amount > total_wsteth_balance"
                    );
                    total_wsteth_balance -= actual_withdrawn_amount;
                }
            }
        }
        for (uint256 i = 0; i < withdrawers.length; i++) {
            uint256 balance = IERC20(deployParams.wsteth).balanceOf(
                withdrawers[i]
            );
            withdrawnAmounts[_indexOf(withdrawers[i])] += balance - balances[i];
        }

        uint256 full_vault_balance_after_processing = _tvl_weth(true);

        cumulative_processed_withdrawals_weth +=
            full_vault_balance_before_processing -
            full_vault_balance_after_processing;
    }

    function validate_invariants() internal view {
        assertLe(
            setup.vault.totalSupply(),
            setup.configurator.maximalTotalSupply(),
            "totalSupply > maximalTotalSupply"
        );

        uint256 full_vault_balance_weth = _tvl_weth(true);
        assertEq(
            full_vault_balance_weth +
                _convert_wsteth_to_weth(
                    cumulative_processed_withdrawals_weth,
                    true
                ),
            cumulative_deposits_weth + deployParams.initialDepositWETH,
            "cumulative_deposits_weth + cumulative_processed_withdrawals_weth != cumulative_deposits_wsteth + wstethAmountDeposited"
        );

        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(deployParams.deployer)
            ),
            "deployer balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(deployParams.proxyAdmin)
            ),
            "proxyAdmin balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(address(deployParams.admin)),
            "admin balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(deployParams.curatorOperator)
            ),
            "curator balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(address(setup.strategy)),
            "strategy balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(address(setup.configurator)),
            "configurator balance not zero"
        );
    }

    function finalize_test() internal {
        for (uint256 i = 0; i < depositors.length; i++) {
            address user = depositors[i];
            if (setup.vault.balanceOf(user) == 0) continue;
            vm.startPrank(user);
            uint256 lpAmount = setup.vault.balanceOf(user) +
                setup.vault.withdrawalRequest(user).lpAmount;
            setup.vault.registerWithdrawal(
                user,
                lpAmount,
                new uint256[](1),
                type(uint256).max,
                type(uint256).max,
                true // close previous withdrawal request
            );
            vm.stopPrank();
        }

        uint256[] memory balances = new uint256[](depositors.length);
        for (uint256 i = 0; i < depositors.length; i++) {
            balances[i] = IERC20(deployParams.wsteth).balanceOf(depositors[i]);
        }

        uint256 full_vault_balance_before_processing = IERC20(
            deployParams.wsteth
        ).balanceOf(address(setup.vault));

        vm.prank(deployParams.curatorOperator);
        setup.strategy.processWithdrawals(depositors, 0);

        for (uint256 i = 0; i < depositors.length; i++) {
            uint256 balance = IERC20(deployParams.wsteth).balanceOf(
                depositors[i]
            );
            withdrawnAmounts[i] += balance - balances[i];
        }

        uint256 full_vault_balance_after_processing = IERC20(
            deployParams.wsteth
        ).balanceOf(address(setup.vault));

        cumulative_processed_withdrawals_weth +=
            full_vault_balance_before_processing -
            full_vault_balance_after_processing;
    }

    function validate_final_invariants() internal view {
        uint256 totalSupply = setup.vault.totalSupply();
        uint256 full_wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );
        uint256 allowed_error = Math.mulDiv(
            full_wsteth_balance,
            MAX_ERROR,
            totalSupply
        ) + MAX_ERROR;

        int256 excess = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            excess += int256(withdrawnAmounts[i]);
            assertLe(
                depositedAmounts[i],
                withdrawnAmounts[i] + allowed_error,
                string.concat(
                    "deposit amounts > withdrawal amounts + allowed_error ",
                    Strings.toString(allowed_error),
                    " ",
                    Strings.toString(depositedAmounts[i]),
                    " ",
                    Strings.toString(withdrawnAmounts[i])
                )
            );
            assertEq(
                0,
                setup.vault.balanceOf(depositors[i]),
                "non-zero balance"
            );
        }
        for (uint256 i = 0; i < depositors.length; i++) {
            excess -= int256(depositedAmounts[i]);
        }
        excess +=
            int256(full_wsteth_balance) -
            int256(deployParams.initialDepositWETH);

        address[] memory pendingWithdrawers = setup.vault.pendingWithdrawers();
        assertEq(0, pendingWithdrawers.length, "pending withdrawals not empty");

        assertLe(
            deployParams.initialDepositWETH,
            IERC20(deployParams.wsteth).balanceOf(address(setup.vault)),
            "wstethAmountDeposited > vault balance"
        );
    }

    /*
        transition_random_deposit
        
        transition_request_random_withdrawal
        transition_process_random_requested_withdrawals_subset

        
        transition_random_wsteth_price_change
        
        transition_convert
        transition_convert_and_deposit

        transition_random_idle_ether_change


    */

    function runSolvencyTest(Actions[] memory) internal {
        set_vault_limit(1e6 ether);

        for (uint256 i = 0; i < 10; i++) {
            transition_random_deposit();
            transition_request_random_withdrawal();
            transition_process_random_requested_withdrawals_subset();
            validate_invariants();
        }

        // finalize_test();
        // validate_invariants();
        // validate_final_invariants();
    }
}
