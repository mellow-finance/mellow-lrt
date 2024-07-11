// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet/Deploy.s.sol";

contract SolvencyTest is DeployScript, Validator, EventValidator, Test {
    using SafeERC20 for IERC20;
    using stdStorage for StdStorage;

    DeployInterfaces.DeployParameters private deployParams;
    DeployInterfaces.DeploySetup private setup;

    uint256 private seed;

    uint256 public constant MAX_ERROR = 10 wei;
    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D18 = 1e18;

    address[] public depositors;
    uint256[] public depositedAmounts;
    uint256[] public withdrawnAmounts;

    uint256 public cumulative_deposits_wsteth;
    uint256 public cumulative_processed_withdrawals_wsteth;
    uint256 public cumulative_rogue_deposits_wsteth;

    function setUp() public {
        string memory rpc = vm.envString("MAINNET_RPC");
        uint256 fork = vm.createFork(rpc, 20017905);
        vm.selectFork(fork);
    }

    function deployVault(uint256 symbioticLimit, uint256 mellowLimit) public {
        seed = 0;
        address curator = DeployConstants.STEAKHOUSE_MULTISIG;
        string memory name = DeployConstants.STEAKHOUSE_VAULT_NAME;
        string memory symbol = DeployConstants.STEAKHOUSE_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_DEPLOYER;
        vm.startPrank(deployParams.deployer);

        deployParams.proxyAdmin = DeployConstants.MELLOW_LIDO_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_MULTISIG;

        deployParams.wstethDefaultBondFactory = DeployConstants
            .WSTETH_DEFAULT_BOND_FACTORY;
        deployParams.wstethDefaultBond = IDefaultCollateralFactory(
            deployParams.wstethDefaultBondFactory
        ).create(DeployConstants.WSTETH, symbioticLimit, address(0));

        deployParams.wsteth = DeployConstants.WSTETH;
        deployParams.steth = DeployConstants.STETH;
        deployParams.weth = DeployConstants.WETH;

        deployParams.initialDepositETH =
            DeployConstants.INITIAL_DEPOSIT_ETH +
            DeployConstants.FIRST_DEPOSIT_ETH;
        deployParams.firstDepositETH = 0;
        deployParams = commonContractsDeploy(deployParams);
        deployParams.curator = curator;
        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;

        deal(
            deployParams.deployer,
            deployParams.initialDepositETH + deployParams.firstDepositETH
        );
        uint256 minRequiredTotalSupply = IWrappedSteth(deployParams.wsteth)
            .getWstETHByStETH(deployParams.deployer.balance) + 1 wei;
        deployParams.maximalTotalSupply = Math.max(
            mellowLimit,
            minRequiredTotalSupply
        );

        vm.recordLogs();
        (deployParams, setup) = deploy(deployParams);
        validateParameters(deployParams, setup, 0);
        validateEvents(deployParams, setup, vm.getRecordedLogs());
        vm.stopPrank();
    }

    function _indexOf(address user) internal view returns (uint256) {
        for (uint256 i = 0; i < depositors.length; i++) {
            if (depositors[i] == user) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function _random() internal returns (uint256) {
        seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, seed))
        );
        return seed;
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
        deal(deployParams.wsteth, user, amount);
        vm.startPrank(user);
        IERC20(deployParams.wsteth).safeIncreaseAllowance(
            address(setup.depositWrapper),
            amount
        );

        uint256 totalSupply = setup.vault.totalSupply();
        uint256 priceX96 = deployParams.priceOracle.priceX96(
            address(setup.vault),
            deployParams.wsteth
        );

        uint256 depositValue = FullMath.mulDiv(amount, priceX96, Q96);
        uint256 totalValue = FullMath.mulDivRoundingUp(
            IERC20(deployParams.wstethDefaultBond).balanceOf(
                address(setup.vault)
            ) + IERC20(deployParams.wsteth).balanceOf(address(setup.vault)),
            priceX96,
            Q96
        );

        uint256 expectedLpAmount = FullMath.mulDiv(
            depositValue,
            totalSupply,
            totalValue
        );

        uint256 lpAmount;
        try
            setup.depositWrapper.deposit(
                user,
                deployParams.wsteth,
                amount,
                0,
                type(uint256).max,
                0
            )
        returns (uint256 lpAmount_) {
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

        cumulative_deposits_wsteth += amount;
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
        uint256 price_before = IWrappedSteth(deployParams.wsteth)
            .getStETHByWstETH(1 ether);
        vm.store(deployParams.steth, slot, bytes32(new_value));
        uint256 price_after = IWrappedSteth(deployParams.wsteth)
            .getStETHByWstETH(1 ether);
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
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            true // close previous withdrawal request
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

        uint256 full_vault_balance_before_processing = IERC20(
            deployParams.wsteth
        ).balanceOf(address(setup.vault)) +
            IERC20(deployParams.wstethDefaultBond).balanceOf(
                address(setup.vault)
            );

        uint256[] memory balances = new uint256[](withdrawers.length);

        for (uint256 i = 0; i < withdrawers.length; i++) {
            balances[i] = IERC20(deployParams.wsteth).balanceOf(withdrawers[i]);
        }

        vm.prank(deployParams.curator);
        setup.defaultBondStrategy.processWithdrawals(withdrawers);

        for (uint256 i = 0; i < withdrawers.length; i++) {
            uint256 balance = IERC20(deployParams.wsteth).balanceOf(
                withdrawers[i]
            );
            withdrawnAmounts[_indexOf(withdrawers[i])] += balance - balances[i];
        }

        uint256 full_vault_balance_after_processing = IERC20(
            deployParams.wsteth
        ).balanceOf(address(setup.vault)) +
            IERC20(deployParams.wstethDefaultBond).balanceOf(
                address(setup.vault)
            );

        cumulative_processed_withdrawals_wsteth +=
            full_vault_balance_before_processing -
            full_vault_balance_after_processing;
    }

    function transfer_rogue_deposit() internal {
        address attacker = random_address();
        vm.startPrank(attacker);
        uint256 amount = calc_random_amount_d18();
        deal(deployParams.wsteth, attacker, amount);
        IERC20(deployParams.wsteth).safeTransfer(address(setup.vault), amount);
        vm.stopPrank();
        cumulative_rogue_deposits_wsteth += amount;
    }

    function validate_invariants() internal view {
        assertLe(
            setup.vault.totalSupply(),
            setup.configurator.maximalTotalSupply(),
            "totalSupply > maximalTotalSupply"
        );

        uint256 full_vault_balance_wsteth = IERC20(deployParams.wsteth)
            .balanceOf(address(setup.vault)) +
            IERC20(deployParams.wstethDefaultBond).balanceOf(
                address(setup.vault)
            );

        assertEq(
            full_vault_balance_wsteth + cumulative_processed_withdrawals_wsteth,
            cumulative_deposits_wsteth +
                setup.wstethAmountDeposited +
                cumulative_rogue_deposits_wsteth,
            "full_vault_balance_wsteth + cumulative_processed_withdrawals_wsteth != cumulative_deposits_wsteth + wstethAmountDeposited + cumulative_rogue_deposits_wsteth"
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
                address(deployParams.curator)
            ),
            "curator balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(setup.defaultBondStrategy)
            ),
            "defaultBondStrategy balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(setup.depositWrapper)
            ),
            "depositWrapper balance not zero"
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
        ).balanceOf(address(setup.vault)) +
            IERC20(deployParams.wstethDefaultBond).balanceOf(
                address(setup.vault)
            );

        vm.prank(deployParams.curator);
        setup.defaultBondStrategy.processWithdrawals(depositors);

        for (uint256 i = 0; i < depositors.length; i++) {
            uint256 balance = IERC20(deployParams.wsteth).balanceOf(
                depositors[i]
            );
            withdrawnAmounts[i] += balance - balances[i];
        }

        uint256 full_vault_balance_after_processing = IERC20(
            deployParams.wsteth
        ).balanceOf(address(setup.vault)) +
            IERC20(deployParams.wstethDefaultBond).balanceOf(
                address(setup.vault)
            );

        cumulative_processed_withdrawals_wsteth +=
            full_vault_balance_before_processing -
            full_vault_balance_after_processing;
    }

    function validate_final_invariants() internal view {
        uint256 totalSupply = setup.vault.totalSupply();
        uint256 full_wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        ) +
            IERC20(deployParams.wstethDefaultBond).balanceOf(
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
            int256(setup.wstethAmountDeposited);
        assertLe(
            excess - int256(allowed_error),
            int256(cumulative_rogue_deposits_wsteth),
            "Excess - allowed_error > cumulative rogue deposits"
        );
        assertLe(
            int256(cumulative_rogue_deposits_wsteth),
            excess + int256(allowed_error),
            "Cumulative rogue deposits < excess + allowed_error"
        );

        address[] memory pendingWithdrawers = setup.vault.pendingWithdrawers();
        assertEq(0, pendingWithdrawers.length, "pending withdrawals not empty");

        assertLe(
            setup.wstethAmountDeposited,
            IERC20(deployParams.wsteth).balanceOf(address(setup.vault)) +
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
            "wstethAmountDeposited > vault balance"
        );
    }

    function testSolvency() external {
        uint256 n = 1000; // n = 1000 -> used gas ~= 2**32, so if set higher, it will fail with OOG
        deployVault(n * 1e6 ether, n * 1e6 ether);
        for (uint256 i = 0; i < n; i++) {
            transition_random_deposit();
            validate_invariants();
            transition_random_wsteth_price_change();
            validate_invariants();
            transition_request_random_withdrawal();
            validate_invariants();
            transition_process_random_requested_withdrawals_subset();
            validate_invariants();
            transfer_rogue_deposit();
            validate_invariants();
        }

        finalize_test();
        validate_invariants();
        validate_final_invariants();
    }

    function testFuzz_SolvencyWithSetOfTransitions(
        uint8 n_,
        uint256 symbioticLimit,
        uint256 mellowLimit,
        uint8 testBitMask
    ) external {
        uint256 n = uint256(n_);
        deployVault(symbioticLimit, mellowLimit);
        for (uint256 i = 0; i < n; i++) {
            if ((testBitMask >> 0) & 1 == 1) {
                transition_random_deposit();
                validate_invariants();
            }
            if ((testBitMask >> 1) & 1 == 1) {
                transition_random_wsteth_price_change();
                validate_invariants();
            }
            if ((testBitMask >> 2) & 1 == 1) {
                transition_request_random_withdrawal();
                validate_invariants();
            }
            if ((testBitMask >> 3) & 1 == 1) {
                transition_process_random_requested_withdrawals_subset();
                validate_invariants();
            }
            if ((testBitMask >> 4) & 1 == 1) {
                transfer_rogue_deposit();
                validate_invariants();
            }
        }

        finalize_test();
        validate_invariants();
        validate_final_invariants();
    }

    function testFuzz_SolvencySequenceOfTransitions(
        uint256 symbioticLimit,
        uint256 mellowLimit,
        uint8[] memory sequence
    ) external {
        uint256 n = sequence.length;
        {
            uint256 iterator = 0;
            for (uint256 i = 0; i < n; i++) {
                sequence[i] = uint8(
                    uint256(keccak256(abi.encode(sequence[i]))) % 5
                );
            }
            assembly {
                mstore(sequence, iterator)
            }
            n = sequence.length;
        }
        // to prevent OOG
        if (n > 5000) {
            n = 5000;
            assembly {
                mstore(sequence, n)
            }
        }
        deployVault(symbioticLimit, mellowLimit);
        for (uint256 i = 0; i < n; i++) {
            if (sequence[i] == 0) {
                transition_random_deposit();
                validate_invariants();
            }
            if (sequence[i] == 1) {
                transition_random_wsteth_price_change();
                validate_invariants();
            } else if (sequence[i] == 2) {
                transition_request_random_withdrawal();
                validate_invariants();
            } else if (sequence[i] == 3) {
                transition_process_random_requested_withdrawals_subset();
                validate_invariants();
            } else if (sequence[i] == 4) {
                transfer_rogue_deposit();
                validate_invariants();
            }
        }
        finalize_test();
        validate_invariants();
        validate_final_invariants();
    }
}
