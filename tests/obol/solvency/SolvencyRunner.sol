// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/obol/Deploy.s.sol";

interface ILidoStakingModule {
    function getNodeOperatorIds(
        uint256 limit,
        uint256 offset
    ) external view returns (uint256[] memory);

    function getNodeOperatorIsActive(uint256 id) external view returns (bool);

    function getNodeOperator(
        uint256 _nodeOperatorId,
        bool _fullInfo
    )
        external
        view
        returns (
            bool active,
            string memory name,
            address rewardAddress,
            uint64 totalVettedValidators,
            uint64 totalExitedValidators,
            uint64 totalAddedValidators,
            uint64 totalDepositedValidators
        );

    function addSigningKeys(
        uint256 _nodeOperatorId,
        uint256 _keysCount,
        bytes memory _publicKeys,
        bytes memory _signatures
    ) external;

    function removeSigningKeys(
        uint256 _nodeOperatorId,
        uint256 _fromIndex,
        uint256 _keysCount
    ) external;

    function getUnusedSigningKeyCount(
        uint256 _nodeOperatorId
    ) external view returns (uint256);
}

interface ILidoStakingRouter {
    struct LidoStakingModule {
        /// @notice unique id of the staking module
        uint24 id;
        /// @notice address of staking module
        address stakingModuleAddress;
        /// @notice part of the fee taken from staking rewards that goes to the staking module
        uint16 stakingModuleFee;
        /// @notice part of the fee taken from staking rewards that goes to the treasury
        uint16 treasuryFee;
        /// @notice target percent of total validators in protocol, in BP
        uint16 targetShare;
        /// @notice staking module status if staking module can not accept the deposits or can participate in further reward distribution
        uint8 status;
        /// @notice name of staking module
        string name;
        /// @notice block.timestamp of the last deposit of the staking module
        /// @dev NB: lastDepositAt gets updated even if the deposit value was 0 and no actual deposit happened
        uint64 lastDepositAt;
        /// @notice block.number of the last deposit of the staking module
        /// @dev NB: lastDepositBlock gets updated even if the deposit value was 0 and no actual deposit happened
        uint256 lastDepositBlock;
        /// @notice number of exited validators
        uint256 exitedValidatorsCount;
    }

    function getStakingModules()
        external
        view
        returns (LidoStakingModule[] memory);
}

contract SolvencyRunner is Test, DeployScript {
    using stdStorage for StdStorage;
    using SafeERC20 for IERC20;

    enum Actions {
        DEPOSIT,
        REGISTER_WITHDRAWAL,
        PROCESS_WITHDRAWALS,
        CONVERT_AND_DEPOSIT,
        CONVERT
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

    bool internal is_stake_limit_disabled = false;

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

    function set_inf_stake_limit() internal {
        bytes32 slot_ = 0xa3678de4a579be090bed1177e0a24f77cc29d181ac22fd7688aca344d8938015;
        bytes32 value = vm.load(deployParams.steth, slot_);
        bytes32 new_value = bytes32(uint256(value) & type(uint160).max); // nullify maxStakeLimit
        vm.store(deployParams.steth, slot_, new_value);
        is_stake_limit_disabled = true;
    }

    function generate_signing_keys(
        uint256 _keysCount
    ) internal returns (bytes memory _publicKeys, bytes memory _signatures) {
        uint256 PUBKEY_LENGTH = 48;
        uint256 SIGNATURE_LENGTH = 96;

        _publicKeys = new bytes(PUBKEY_LENGTH * _keysCount);
        _signatures = new bytes(SIGNATURE_LENGTH * _keysCount);

        for (uint256 i = 0; i < _keysCount; i++) {
            for (uint256 j = 0; j < PUBKEY_LENGTH; j++) {
                _publicKeys[i * PUBKEY_LENGTH + j] = bytes1(uint8(_random()));
            }
            for (uint256 j = 0; j < SIGNATURE_LENGTH; j++) {
                _signatures[i * SIGNATURE_LENGTH + j] = bytes1(
                    uint8(_random())
                );
            }
        }
    }

    function add_validator_keys(
        uint256 stakingModuleId,
        uint256 keysCount
    ) internal {
        IDepositSecurityModule dsm = IDepositSecurityModule(
            ILidoLocator(deployParams.lidoLocator).depositSecurityModule()
        );
        ILidoStakingModule lidoStakingModule = ILidoStakingModule(
            ILidoStakingRouter(dsm.STAKING_ROUTER())
            .getStakingModules()[stakingModuleId].stakingModuleAddress
        );

        uint256[] memory nodeOperatorIds = lidoStakingModule.getNodeOperatorIds(
            0,
            1024
        );
        for (uint256 i = 0; i < nodeOperatorIds.length; i++) {
            if (!lidoStakingModule.getNodeOperatorIsActive(nodeOperatorIds[i]))
                continue;
            add_signing_keys(lidoStakingModule, nodeOperatorIds[i], keysCount);

            return;
        }
        revert("No active node operators found");
    }

    function add_signing_keys(
        ILidoStakingModule lidoStakingModule,
        uint256 _nodeOperatorId,
        uint256 _keysCount
    ) internal {
        (bool active, , address rewardAddress, , , , ) = lidoStakingModule
            .getNodeOperator(_nodeOperatorId, false);

        if (!active) return;
        (
            bytes memory _publicKeys,
            bytes memory _signatures
        ) = generate_signing_keys(_keysCount);
        vm.startPrank(rewardAddress);
        lidoStakingModule.addSigningKeys(
            _nodeOperatorId,
            _keysCount,
            _publicKeys,
            _signatures
        );
    }

    function remove_validator_keys(
        uint256 stakingModuleId,
        uint256 keysCount
    ) internal {
        IDepositSecurityModule dsm = IDepositSecurityModule(
            ILidoLocator(deployParams.lidoLocator).depositSecurityModule()
        );
        ILidoStakingModule lidoStakingModule = ILidoStakingModule(
            ILidoStakingRouter(dsm.STAKING_ROUTER())
            .getStakingModules()[stakingModuleId].stakingModuleAddress
        );

        uint256[] memory nodeOperatorIds = lidoStakingModule.getNodeOperatorIds(
            0,
            1024
        );
        for (uint256 i = 0; i < nodeOperatorIds.length && keysCount != 0; i++) {
            if (!lidoStakingModule.getNodeOperatorIsActive(nodeOperatorIds[i]))
                continue;
            keysCount = remove_signing_keys(
                lidoStakingModule,
                nodeOperatorIds[i],
                keysCount
            );
        }
    }

    function remove_signing_keys(
        ILidoStakingModule lidoStakingModule,
        uint256 _nodeOperatorId,
        uint256 _keysCount
    ) internal returns (uint256 left) {
        (
            bool active,
            ,
            address rewardAddress,
            ,
            ,
            ,
            uint64 totalDepositedValidators
        ) = lidoStakingModule.getNodeOperator(_nodeOperatorId, false);
        if (!active) return _keysCount;

        uint256 unusedKeys = lidoStakingModule.getUnusedSigningKeyCount(
            _nodeOperatorId
        );
        unusedKeys = Math.min(unusedKeys, _keysCount);
        if (unusedKeys == 0) return _keysCount;

        vm.startPrank(rewardAddress);
        try
            lidoStakingModule.removeSigningKeys(
                _nodeOperatorId,
                totalDepositedValidators,
                unusedKeys
            )
        {
            _keysCount -= unusedKeys;
        } catch {}
        return _keysCount;
    }

    function transition_random_validator_limits_and_usage() internal {
        ILidoLocator locator = ILidoLocator(deployParams.lidoLocator);

        IDepositSecurityModule dsm = IDepositSecurityModule(
            locator.depositSecurityModule()
        );
        ILidoStakingRouter router = ILidoStakingRouter(dsm.STAKING_ROUTER());
        ILidoStakingRouter.LidoStakingModule[] memory stakingModules = router
            .getStakingModules();

        for (uint256 i = 0; i < stakingModules.length; i++) {
            if (random_bool()) {
                // add new keys
                uint256 keysCount = _randInt(1, 128);
                add_validator_keys(i, keysCount);
            }

            if (random_bool()) {
                // remove keys
                uint256 keysCount = _randInt(1, 128);
                remove_validator_keys(i, keysCount);
            }
        }
    }

    Vm.Wallet private _guardian;
    bool private _is_guardian_set = false;

    function get_convert_and_deposit_params(
        IDepositSecurityModule depositSecurityModule,
        uint256 blockNumber
    )
        public
        returns (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        )
    {
        if (!_is_guardian_set) {
            _guardian = vm.createWallet("guardian");
            vm.startPrank(depositSecurityModule.getOwner());
            // nullify minDepositBlockDistance
            vm.store(
                address(depositSecurityModule),
                bytes32(uint256(1)),
                bytes32(0)
            );
            depositSecurityModule.addGuardian(_guardian.addr, 1);
            vm.stopPrank();
            _is_guardian_set = true;
        }

        blockHash = blockhash(blockNumber);
        assertNotEq(bytes32(0), blockHash);
        uint256 stakingModuleId = DeployConstants.SIMPLE_DVT_MODULE_ID;
        depositRoot = IDepositContract(depositSecurityModule.DEPOSIT_CONTRACT())
            .get_deposit_root();
        nonce = IStakingRouter(depositSecurityModule.STAKING_ROUTER())
            .getStakingModuleNonce(stakingModuleId);
        depositCalldata = new bytes(0);
        bytes32 attest_message_prefix;
        if (block.chainid == 1) {
            attest_message_prefix = 0xd85557c963041ae93cfa5927261eeb189c486b6d293ccee7da72ca9387cc241d;
        } else {
            // chain id == 17000
            attest_message_prefix = 0xc7cfa471a8a16980de8314ea3a88ebcafb38ae7fb767d792017e90cf637d731b;
        }

        bytes32 message = keccak256(
            abi.encodePacked(
                attest_message_prefix,
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_guardian, message);
        sigs = new IDepositSecurityModule.Signature[](1);
        uint8 parity = v - 27;
        sigs[0] = IDepositSecurityModule.Signature({
            r: r,
            vs: bytes32(uint256(s) | (uint256(parity) << 255))
        });
        address signerAddr = ecrecover(message, v, r, s);
        assertEq(signerAddr, _guardian.addr);
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
        factor_x96 = factor_x96 / 1 ether;
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
            "invalid wsteth price after transition"
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
            true // close previous withdrawal request
        );
        vm.stopPrank();
    }

    function transition_process_random_requested_withdrawals_subset(
        bool is_forced_processing
    ) internal {
        address[] memory withdrawers = setup.vault.pendingWithdrawers();
        if (withdrawers.length == 0) {
            // nothing to process
            return;
        }

        if (!is_forced_processing) {
            uint256 numberOfWithdrawals = _randInt(0, withdrawers.length - 1);
            // random shuffle
            for (uint256 i = 1; i < withdrawers.length; i++) {
                uint256 j = _randInt(0, i);
                (withdrawers[i], withdrawers[j]) = (
                    withdrawers[j],
                    withdrawers[i]
                );
            }

            assembly {
                mstore(withdrawers, numberOfWithdrawals)
            }
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

        if (random_bool() && !is_forced_processing) {
            // do not swap weth->wsteth.
            // withdrawal will occur only for withdrawers[i] |
            // wsteth_vault_balance - actual_withdrawals >= expected_withdraw_amount[i]
            uint256 total_wsteth_balance = IERC20(deployParams.wsteth)
                .balanceOf(address(setup.vault));

            vm.prank(deployParams.curatorOperator);
            bool[] memory statuses = setup.strategy.processWithdrawals(
                withdrawers,
                0
            );

            for (uint256 i = 0; i < withdrawers.length; i++) {
                uint256 actual_withdrawn_amount = IERC20(deployParams.wsteth)
                    .balanceOf(withdrawers[i]) - balances[i];
                if (actual_withdrawn_amount == 0) {
                    assertFalse(statuses[i]);
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
                    assertTrue(statuses[i]);
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
                uint256 wsteth_withdraw_attempt;
                if (is_forced_processing) {
                    wsteth_withdraw_attempt = total_wsteth_balance;
                } else {
                    wsteth_withdraw_attempt = _randInt(total_wsteth_balance);
                }

                uint256 wsteth_required = 0;

                for (
                    uint256 i = 0;
                    i < expected_processed_withdrawals.length;
                    i++
                ) {
                    if (expected_wsteth_amounts[i] <= wsteth_withdraw_attempt) {
                        wsteth_withdraw_attempt -= expected_wsteth_amounts[i];
                        wsteth_required += expected_wsteth_amounts[i];
                        expected_processed_withdrawals[i] = true;
                    } else if (is_forced_processing) {
                        expected_processed_withdrawals[i] = true;
                    }
                }
                wsteth_required = wsteth_required > total_wsteth_balance
                    ? wsteth_required - total_wsteth_balance
                    : 0;
                uint256 weth_required = _convert_wsteth_to_weth(
                    wsteth_required,
                    true
                );

                if (is_forced_processing) {
                    weth_required = IERC20(deployParams.weth).balanceOf(
                        address(setup.vault)
                    );
                }
                if (weth_required != 0) {
                    vm.startPrank(deployParams.curatorAdmin);
                    (bool success, ) = setup.vault.delegateCall(
                        address(deployParams.stakingModule),
                        abi.encodeWithSelector(
                            StakingModule.convert.selector,
                            weth_required
                        )
                    );
                    vm.stopPrank();
                    require(
                        success,
                        "transition_process_random_requested_withdrawals_subset: weth to wsteht conversion failed (probably STAKE_LIMIT)"
                    );
                }
                uint256 new_wsteth_balance = IERC20(deployParams.wsteth)
                    .balanceOf(address(setup.vault));

                assertApproxEqAbs(
                    new_wsteth_balance,
                    total_wsteth_balance +
                        _convert_weth_to_wsteth(weth_required, false),
                    weth_required / 1e18 + MAX_ERROR,
                    "transition_process_random_requested_withdrawals_subset: invalid wsteth balance after conversion"
                );

                total_wsteth_balance = new_wsteth_balance;
            }

            vm.prank(deployParams.curatorOperator);
            bool[] memory statuses = setup.strategy.processWithdrawals(
                withdrawers,
                0
            );

            for (uint256 i = 0; i < withdrawers.length; i++) {
                uint256 actual_withdrawn_amount = IERC20(deployParams.wsteth)
                    .balanceOf(withdrawers[i]) - balances[i];
                if (actual_withdrawn_amount == 0) {
                    assertFalse(
                        statuses[i],
                        "unexpected withdrawal (statuses)"
                    );
                    assertFalse(
                        expected_processed_withdrawals[i],
                        "unexpected withdrawal (expected_processed_withdrawals)"
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
                        statuses[i],
                        "withdrawal not processed (statuses)"
                    );
                    assertTrue(
                        expected_processed_withdrawals[i],
                        "withdrawal not processed (expected_processed_withdrawals)"
                    );
                    assertApproxEqAbs(
                        actual_withdrawn_amount,
                        expected_wsteth_amounts[i],
                        actual_withdrawn_amount / 1 ether + MAX_ERROR,
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
            "validate_invariants: totalSupply > maximalTotalSupply"
        );

        uint256 full_vault_balance_weth = _tvl_weth(true);
        assertApproxEqAbs(
            full_vault_balance_weth + cumulative_processed_withdrawals_weth,
            cumulative_deposits_weth + deployParams.initialDepositWETH,
            cumulative_deposits_weth / 1 ether + MAX_ERROR,
            "validate_invariants: cumulative_deposits_weth + cumulative_processed_withdrawals_weth != cumulative_deposits_wsteth + wstethAmountDeposited"
        );

        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(deployParams.deployer)
            ),
            "validate_invariants: deployer balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(deployParams.proxyAdmin)
            ),
            "validate_invariants: proxyAdmin balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(address(deployParams.admin)),
            "validate_invariants: admin balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(
                address(deployParams.curatorOperator)
            ),
            "validate_invariants: curator balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(address(setup.strategy)),
            "validate_invariants: strategy balance not zero"
        );
        assertEq(
            0,
            IERC20(deployParams.wsteth).balanceOf(address(setup.configurator)),
            "validate_invariants: configurator balance not zero"
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
                new uint256[](2),
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

        uint256 wsteth_balance_before = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );
        uint256 weth_balance_before = IERC20(deployParams.weth).balanceOf(
            address(setup.vault)
        );

        transition_process_random_requested_withdrawals_subset(true);

        for (uint256 i = 0; i < depositors.length; i++) {
            uint256 balance = IERC20(deployParams.wsteth).balanceOf(
                depositors[i]
            );
            withdrawnAmounts[i] += balance - balances[i];
        }

        uint256 wsteth_balance_after = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );
        uint256 weth_balance_after = IERC20(deployParams.weth).balanceOf(
            address(setup.vault)
        );

        assertLe(
            wsteth_balance_after,
            wsteth_balance_before + setup.strategy.maxAllowedRemainder(),
            "invalid wsteth balance after processWithdrawals"
        );

        if (weth_balance_before != weth_balance_after) {
            assertLe(
                wsteth_balance_after,
                setup.strategy.maxAllowedRemainder(),
                "invalid wsteth balance after processWithdrawals (wsteth_balance_after > max_allowed_remainder)"
            );
        }
    }

    function validate_final_invariants() internal view {
        uint256 full_wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );
        uint256 allowed_error = cumulative_deposits_weth / 1e18 + MAX_ERROR;
        int256 excess = 0;

        for (uint256 i = 0; i < depositors.length; i++) {
            excess += int256(withdrawnAmounts[i]);
            uint256 deposit_amount_in_wsteth = _convert_weth_to_wsteth(
                depositedAmounts[i],
                false
            );

            assertEq(
                0,
                setup.vault.balanceOf(depositors[i]),
                "validate_final_invariants: non-zero vault balance"
            );

            assertEq(
                0,
                setup.vault.withdrawalRequest(depositors[i]).lpAmount,
                "validate_final_invariants: non-zero withdrawal request"
            );

            assertLe(
                deposit_amount_in_wsteth,
                withdrawnAmounts[i] + allowed_error,
                string.concat(
                    "validate_final_invariants: deposit amounts > withdrawal amounts + allowed_error. Allowed error: ",
                    Strings.toString(allowed_error),
                    " deposit_amount_in_wsteth: ",
                    Strings.toString(deposit_amount_in_wsteth),
                    " withdrawn_amounts: ",
                    Strings.toString(withdrawnAmounts[i])
                )
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
            _convert_weth_to_wsteth(deployParams.initialDepositWETH, false),
            IERC20(deployParams.wsteth).balanceOf(address(setup.vault)),
            "validate_final_invariants: deposit amount > vault balance after all withdrawals"
        );
    }

    function transition_convert() internal {
        uint256 weth_balance = IERC20(deployParams.weth).balanceOf(
            address(setup.vault)
        );

        uint256 random_ratio = random_float_x96(1, 100) / 100;
        uint256 weth_amount = Math.mulDiv(weth_balance, random_ratio, Q96);
        if (weth_amount == 0) return;

        uint256 wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );

        vm.startPrank(deployParams.curatorAdmin);
        (bool success, bytes memory response) = setup.vault.delegateCall(
            address(deployParams.stakingModule),
            abi.encodeWithSelector(StakingModule.convert.selector, weth_amount)
        );
        vm.stopPrank();

        if (success) {
            uint256 new_weth_balance = IERC20(deployParams.weth).balanceOf(
                address(setup.vault)
            );
            uint256 new_wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
                address(setup.vault)
            );

            assertApproxEqAbs(
                weth_balance - weth_amount,
                new_weth_balance,
                1 wei,
                "transition_convert: invalid weth balance after conversion"
            );

            assertApproxEqAbs(
                wsteth_balance + _convert_weth_to_wsteth(weth_amount, false),
                new_wsteth_balance,
                new_wsteth_balance / 1 ether,
                "transition_convert: invalid wsteth balance after conversion"
            );
        } else {
            uint256 length = response.length;
            assembly {
                response := add(response, 4)
                mstore(response, sub(length, 4))
            }
            string memory reason = abi.decode(response, (string));
            assertEq(
                keccak256(abi.encodePacked(reason)),
                keccak256(abi.encodePacked("STAKE_LIMIT")),
                "unexpected revert"
            );

            require(
                !is_stake_limit_disabled,
                "transition_convert: unexpected revert with flag is_stake_limit_disabled"
            );
        }
    }

    function transition_convert_and_deposit() internal {
        uint256 weth_balance = IERC20(deployParams.weth).balanceOf(
            address(setup.vault)
        );
        uint256 wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
            address(setup.vault)
        );

        uint256 blockNumber = block.number - 1;
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        ) = get_convert_and_deposit_params(
                IDepositSecurityModule(
                    deployParams
                        .stakingModule
                        .lidoLocator()
                        .depositSecurityModule()
                ),
                blockNumber
            );

        address random_user = random_address();
        vm.startPrank(random_user);

        try
            setup.strategy.convertAndDeposit(
                blockNumber,
                blockHash,
                depositRoot,
                nonce,
                depositCalldata,
                sigs
            )
        {
            uint256 new_weth_balance = IERC20(deployParams.weth).balanceOf(
                address(setup.vault)
            );
            uint256 new_wsteth_balance = IERC20(deployParams.wsteth).balanceOf(
                address(setup.vault)
            );

            uint256 weth_change = weth_balance - new_weth_balance;
            uint256 wsteth_change = new_wsteth_balance - wsteth_balance;

            assertApproxEqAbs(
                weth_change,
                IWSteth(deployParams.wsteth).getStETHByWstETH(wsteth_change),
                1 wei,
                "weth_change != wsteth_change"
            );
        } catch {
            console2.log("Deposit and convert failed");
        }

        vm.stopPrank();
    }

    function runSolvencyTest(Actions[] memory actions) internal {
        set_inf_stake_limit();
        set_vault_limit(1e6 ether);

        for (
            uint256 actionIndex = 0;
            actionIndex < actions.length;
            actionIndex++
        ) {
            Actions action = actions[actionIndex];
            if (action == Actions.DEPOSIT) {
                transition_random_deposit();
            } else if (action == Actions.REGISTER_WITHDRAWAL) {
                transition_request_random_withdrawal();
            } else if (action == Actions.PROCESS_WITHDRAWALS) {
                transition_process_random_requested_withdrawals_subset(false);
            } else if (action == Actions.CONVERT) {
                transition_convert();
            } else if (action == Actions.CONVERT_AND_DEPOSIT) {
                transition_convert_and_deposit();
            }
            validate_invariants();
        }

        finalize_test();
        validate_invariants();
        validate_final_invariants();
    }
}
