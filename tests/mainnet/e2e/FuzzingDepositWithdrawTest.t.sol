// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet/Deploy.s.sol";

contract FuzzingDepositWithdrawTest is DeployScript, Validator, Test {
    using SafeERC20 for IERC20;

    DeployInterfaces.DeployParameters deployParams;
    DeployInterfaces.DeploySetup setup;

    uint256 private seed;
    // uint256 private constant userCount = 2;

    uint256 public constant MAX_USERS = 4;
    uint256 public constant MAX_ERROR_DEPOSIT = 4 wei;
    uint256 public constant Q96 = 2 ** 96;

    function setUp() public {
        seed = 0;
        bool test = true;
        address curator = DeployConstants.STEAKHOUSE_MULTISIG;
        string memory name = DeployConstants.STEAKHOUSE_VAULT_NAME;
        string memory symbol = DeployConstants.STEAKHOUSE_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_DEPLOYER;
        vm.startBroadcast(deployParams.deployer);

        deployParams.proxyAdmin = DeployConstants.MELLOW_LIDO_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_MULTISIG;

        // only for testing purposes
        if (test) {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY;
        } else {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY;
        }

        deployParams.wsteth = DeployConstants.WSTETH;
        deployParams.steth = DeployConstants.STETH;
        deployParams.weth = DeployConstants.WETH;

        deployParams.maximalTotalSupply = DeployConstants.MAXIMAL_TOTAL_SUPPLY;
        deployParams.initialDepositETH = DeployConstants.INITIAL_DEPOSIT_ETH;
        deployParams.firstDepositETH = DeployConstants.FIRST_DEPOSIT_ETH;
        deployParams = commonContractsDeploy(deployParams);
        deployParams.curator = curator;
        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;

        (deployParams, setup) = deploy(deployParams);

        validateParameters(deployParams, setup, 0);
        if (false) {
            setup.depositWrapper.deposit{value: deployParams.firstDepositETH}(
                deployParams.deployer,
                address(0),
                deployParams.firstDepositETH,
                0,
                type(uint256).max
            );
        }
        vm.stopBroadcast();
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

    function testFuzz_RandomDeposit_ETH_Withdraw(
        uint64[] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 initialTotalSupply = setup.vault.totalSupply();
        seed = seedRandom;

        if (randomAmounts.length > MAX_USERS) {
            assembly {
                mstore(randomAmounts, MAX_USERS)
            }
        }
        address[] memory users = new address[](randomAmounts.length);
        for (uint160 i = 0; i < users.length; i++) {
            users[i] = vm
                .createWallet(string.concat("user-", Strings.toString(i + 1)))
                .addr;
            randomAmounts[i] = uint64(
                Math.max(uint256(randomAmounts[i]), 1000 wei)
            );
        }

        // initial deposits
        {
            uint256 issuedTotalSupply = 0;
            for (uint160 i = 0; i < users.length; i++) {
                address user = users[i];
                vm.startPrank(user);

                uint64 amount = randomAmounts[i];
                deal(user, amount);
                uint256 totalSupply = setup.vault.totalSupply();
                uint256 priceX96 = deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                );

                uint256 depositValue = FullMath.mulDiv(
                    IWSteth(deployParams.wsteth).getWstETHByStETH(amount),
                    priceX96,
                    Q96
                );

                assertApproxEqAbs(depositValue, amount, MAX_ERROR_DEPOSIT);

                uint256 totalValue = FullMath.mulDivRoundingUp(
                    IERC20(deployParams.wstethDefaultBond).balanceOf(
                        address(setup.vault)
                    ),
                    priceX96,
                    Q96
                );

                uint256 expectedLpAmount = FullMath.mulDiv(
                    depositValue,
                    totalSupply,
                    totalValue
                );

                uint256 lpAmount = setup.depositWrapper.deposit{value: amount}(
                    user,
                    address(0),
                    amount,
                    0,
                    type(uint256).max
                );

                assertEq(expectedLpAmount, lpAmount);
                vm.stopPrank();
                assertEq(lpAmount, IERC20(setup.vault).balanceOf(user));
                assertEq(totalSupply + lpAmount, setup.vault.totalSupply());
                assertLe(
                    setup.vault.totalSupply(),
                    setup.configurator.maximalTotalSupply()
                );
                issuedTotalSupply += lpAmount;
            }
            assertEq(
                issuedTotalSupply + initialTotalSupply,
                setup.vault.totalSupply()
            );
        }

        // random withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = _randInt(userLpAmount);
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // full withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = userLpAmount;
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // nothing to withdraw
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = setup.vault.balanceOf(user);
            assertEq(amount, 0, "Non-zero amounts");
        }

        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();
        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertLe(baseTvlInit[i], baseTvlAfter[i]);
            assertGe(
                baseTvlInit[i] + users.length * MAX_ERROR_DEPOSIT,
                baseTvlAfter[i]
            );
        }
    }

    function testFuzz_RandomDeposit_WETH_Withdraw(
        uint64[] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 initialTotalSupply = setup.vault.totalSupply();
        seed = seedRandom;

        if (randomAmounts.length > MAX_USERS) {
            assembly {
                mstore(randomAmounts, MAX_USERS)
            }
        }
        address[] memory users = new address[](randomAmounts.length);
        for (uint160 i = 0; i < users.length; i++) {
            users[i] = vm
                .createWallet(string.concat("user-", Strings.toString(i + 1)))
                .addr;
            randomAmounts[i] = uint64(
                Math.max(uint256(randomAmounts[i]), 1000 wei)
            );
        }

        // initial deposits
        {
            uint256 issuedTotalSupply = 0;
            for (uint160 i = 0; i < users.length; i++) {
                address user = users[i];
                vm.startPrank(user);

                uint64 amount = randomAmounts[i];
                deal(deployParams.weth, user, amount);
                uint256 totalSupply = setup.vault.totalSupply();
                uint256 priceX96 = deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                );

                uint256 depositValue = FullMath.mulDiv(
                    IWSteth(deployParams.wsteth).getWstETHByStETH(amount),
                    priceX96,
                    Q96
                );

                assertApproxEqAbs(depositValue, amount, MAX_ERROR_DEPOSIT);

                uint256 totalValue = FullMath.mulDivRoundingUp(
                    IERC20(deployParams.wstethDefaultBond).balanceOf(
                        address(setup.vault)
                    ),
                    priceX96,
                    Q96
                );

                uint256 expectedLpAmount = FullMath.mulDiv(
                    depositValue,
                    totalSupply,
                    totalValue
                );

                IERC20(deployParams.weth).safeIncreaseAllowance(
                    address(setup.depositWrapper),
                    amount
                );
                uint256 lpAmount = setup.depositWrapper.deposit(
                    user,
                    deployParams.weth,
                    amount,
                    0,
                    type(uint256).max
                );

                assertEq(expectedLpAmount, lpAmount);
                vm.stopPrank();
                assertEq(lpAmount, IERC20(setup.vault).balanceOf(user));
                assertEq(totalSupply + lpAmount, setup.vault.totalSupply());
                assertLe(
                    setup.vault.totalSupply(),
                    setup.configurator.maximalTotalSupply()
                );
                issuedTotalSupply += lpAmount;
            }
            assertEq(
                issuedTotalSupply + initialTotalSupply,
                setup.vault.totalSupply()
            );
        }

        // random withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = _randInt(userLpAmount);
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // full withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = userLpAmount;
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // nothing to withdraw
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = setup.vault.balanceOf(user);
            assertEq(amount, 0, "Non-zero amounts");
        }

        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();
        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertLe(baseTvlInit[i], baseTvlAfter[i]);
            assertGe(
                baseTvlInit[i] + users.length * MAX_ERROR_DEPOSIT,
                baseTvlAfter[i]
            );
        }
    }

    function testFuzz_RandomDeposit_STETH_Withdraw(
        uint64[] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 initialTotalSupply = setup.vault.totalSupply();
        seed = seedRandom;

        if (randomAmounts.length > MAX_USERS) {
            assembly {
                mstore(randomAmounts, MAX_USERS)
            }
        }
        address[] memory users = new address[](randomAmounts.length);
        for (uint160 i = 0; i < users.length; i++) {
            users[i] = vm
                .createWallet(string.concat("user-", Strings.toString(i + 1)))
                .addr;
            randomAmounts[i] = uint64(
                Math.max(uint256(randomAmounts[i]), 1000 wei)
            );
        }

        // initial deposits
        {
            uint256 issuedTotalSupply = 0;
            for (uint160 i = 0; i < users.length; i++) {
                address user = users[i];
                vm.startPrank(user);

                uint64 amount = randomAmounts[i];
                deal(user, amount);
                ISteth(deployParams.steth).submit{value: amount}(address(0));
                uint256 totalSupply = setup.vault.totalSupply();
                uint256 priceX96 = deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                );

                uint256 depositValue = FullMath.mulDiv(
                    IWSteth(deployParams.wsteth).getWstETHByStETH(amount),
                    priceX96,
                    Q96
                );

                assertApproxEqAbs(depositValue, amount, MAX_ERROR_DEPOSIT);

                uint256 totalValue = FullMath.mulDivRoundingUp(
                    IERC20(deployParams.wstethDefaultBond).balanceOf(
                        address(setup.vault)
                    ),
                    priceX96,
                    Q96
                );

                uint256 expectedLpAmount = FullMath.mulDiv(
                    depositValue,
                    totalSupply,
                    totalValue
                );

                IERC20(deployParams.steth).safeIncreaseAllowance(
                    address(setup.depositWrapper),
                    amount
                );
                uint256 lpAmount = setup.depositWrapper.deposit(
                    user,
                    deployParams.steth,
                    amount,
                    0,
                    type(uint256).max
                );

                assertEq(expectedLpAmount, lpAmount);
                vm.stopPrank();
                assertEq(lpAmount, IERC20(setup.vault).balanceOf(user));
                assertEq(totalSupply + lpAmount, setup.vault.totalSupply());
                assertLe(
                    setup.vault.totalSupply(),
                    setup.configurator.maximalTotalSupply()
                );
                issuedTotalSupply += lpAmount;
            }
            assertEq(
                issuedTotalSupply + initialTotalSupply,
                setup.vault.totalSupply()
            );
        }

        // random withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = _randInt(userLpAmount);
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // full withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = userLpAmount;
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // nothing to withdraw
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = setup.vault.balanceOf(user);
            assertEq(amount, 0, "Non-zero amounts");
        }

        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();
        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertLe(baseTvlInit[i], baseTvlAfter[i]);
            assertGe(
                baseTvlInit[i] + users.length * MAX_ERROR_DEPOSIT,
                baseTvlAfter[i]
            );
        }
    }

    function testFuzz_RandomDeposit_WSTETH_Withdraw(
        uint64[] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 initialTotalSupply = setup.vault.totalSupply();
        seed = seedRandom;

        if (randomAmounts.length > MAX_USERS) {
            assembly {
                mstore(randomAmounts, MAX_USERS)
            }
        }
        address[] memory users = new address[](randomAmounts.length);
        for (uint160 i = 0; i < users.length; i++) {
            users[i] = vm
                .createWallet(string.concat("user-", Strings.toString(i + 1)))
                .addr;
            randomAmounts[i] = uint64(
                Math.max(uint256(randomAmounts[i]), 1000 wei)
            );
        }

        // initial deposits
        {
            uint256 issuedTotalSupply = 0;
            for (uint160 i = 0; i < users.length; i++) {
                address user = users[i];
                vm.startPrank(user);

                uint64 amount = randomAmounts[i];
                deal(deployParams.wsteth, user, amount);
                uint256 totalSupply = setup.vault.totalSupply();
                uint256 priceX96 = deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                );

                uint256 depositValue = FullMath.mulDiv(amount, priceX96, Q96);

                assertApproxEqAbs(
                    depositValue,
                    IWSteth(deployParams.wsteth).getStETHByWstETH(amount),
                    MAX_ERROR_DEPOSIT
                );

                uint256 totalValue = FullMath.mulDivRoundingUp(
                    IERC20(deployParams.wstethDefaultBond).balanceOf(
                        address(setup.vault)
                    ),
                    priceX96,
                    Q96
                );

                uint256 expectedLpAmount = FullMath.mulDiv(
                    depositValue,
                    totalSupply,
                    totalValue
                );

                IERC20(deployParams.wsteth).safeIncreaseAllowance(
                    address(setup.depositWrapper),
                    amount
                );
                uint256 lpAmount = setup.depositWrapper.deposit(
                    user,
                    deployParams.wsteth,
                    amount,
                    0,
                    type(uint256).max
                );

                assertEq(expectedLpAmount, lpAmount);
                vm.stopPrank();
                assertEq(lpAmount, IERC20(setup.vault).balanceOf(user));
                assertEq(totalSupply + lpAmount, setup.vault.totalSupply());
                assertLe(
                    setup.vault.totalSupply(),
                    setup.configurator.maximalTotalSupply()
                );
                issuedTotalSupply += lpAmount;
            }
            assertEq(
                issuedTotalSupply + initialTotalSupply,
                setup.vault.totalSupply()
            );
        }

        // random withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = _randInt(userLpAmount);
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // full withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = userLpAmount;
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // nothing to withdraw
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = setup.vault.balanceOf(user);
            assertEq(amount, 0, "Non-zero amounts");
        }

        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();
        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertLe(baseTvlInit[i], baseTvlAfter[i]);
            assertGe(
                baseTvlInit[i] + users.length * MAX_ERROR_DEPOSIT,
                baseTvlAfter[i]
            );
        }
    }

    function testFuzz_RandomDeposit_WSTETH_Withdraw_DirectDeposit(
        uint64[] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 initialTotalSupply = setup.vault.totalSupply();
        seed = seedRandom;

        if (randomAmounts.length > MAX_USERS) {
            assembly {
                mstore(randomAmounts, MAX_USERS)
            }
        }
        address[] memory users = new address[](randomAmounts.length);
        for (uint160 i = 0; i < users.length; i++) {
            users[i] = vm
                .createWallet(string.concat("user-", Strings.toString(i + 1)))
                .addr;
            randomAmounts[i] = uint64(
                Math.max(uint256(randomAmounts[i]), 1000 wei)
            );
        }

        // initial deposits
        {
            uint256 issuedTotalSupply = 0;
            for (uint160 i = 0; i < users.length; i++) {
                address user = users[i];
                vm.startPrank(user);

                uint64 amount = randomAmounts[i];
                deal(deployParams.wsteth, user, amount);
                uint256 totalSupply = setup.vault.totalSupply();
                uint256 priceX96 = deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                );

                uint256 depositValue = FullMath.mulDiv(amount, priceX96, Q96);

                assertApproxEqAbs(
                    depositValue,
                    IWSteth(deployParams.wsteth).getStETHByWstETH(amount),
                    MAX_ERROR_DEPOSIT
                );

                uint256 totalValue = FullMath.mulDivRoundingUp(
                    IERC20(deployParams.wstethDefaultBond).balanceOf(
                        address(setup.vault)
                    ),
                    priceX96,
                    Q96
                );

                uint256 expectedLpAmount = FullMath.mulDiv(
                    depositValue,
                    totalSupply,
                    totalValue
                );

                IERC20(deployParams.wsteth).safeIncreaseAllowance(
                    address(setup.vault),
                    amount
                );
                uint256[] memory amounts = new uint256[](1);
                amounts[0] = amount;
                (, uint256 lpAmount) = setup.vault.deposit(
                    user,
                    amounts,
                    0,
                    type(uint256).max
                );

                assertEq(expectedLpAmount, lpAmount);
                vm.stopPrank();
                assertEq(lpAmount, IERC20(setup.vault).balanceOf(user));
                assertEq(totalSupply + lpAmount, setup.vault.totalSupply());
                assertLe(
                    setup.vault.totalSupply(),
                    setup.configurator.maximalTotalSupply()
                );
                issuedTotalSupply += lpAmount;
            }
            assertEq(
                issuedTotalSupply + initialTotalSupply,
                setup.vault.totalSupply()
            );
        }

        // random withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = _randInt(userLpAmount);
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // full withdrawals
        {
            uint256 burnedTotalSupply = 0;
            uint256 totalSupplyBeforeWithdrawals = setup.vault.totalSupply();
            for (uint256 i = 0; i < users.length; i++) {
                address user = users[i];
                uint256 userLpAmount = setup.vault.balanceOf(user);
                uint256 withdrawalLpAmount = userLpAmount;
                if (withdrawalLpAmount == 0) continue;
                vm.startPrank(user);
                setup.vault.registerWithdrawal(
                    user,
                    withdrawalLpAmount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                burnedTotalSupply += setup
                    .vault
                    .withdrawalRequest(user)
                    .lpAmount;
                assertLe(
                    setup.vault.withdrawalRequest(user).lpAmount,
                    withdrawalLpAmount
                );
                assertEq(
                    setup.vault.balanceOf(user) +
                        setup.vault.withdrawalRequest(user).lpAmount,
                    userLpAmount
                );
            }

            // rounding down
            uint256 totalValue = FullMath.mulDiv(
                IERC20(deployParams.wstethDefaultBond).balanceOf(
                    address(setup.vault)
                ),
                deployParams.priceOracle.priceX96(
                    address(setup.vault),
                    deployParams.wsteth
                ),
                Q96
            );

            uint256[] memory wstethBalances = new uint256[](users.length);
            uint256[] memory expectedWithdrawalAmounts = new uint256[](
                users.length
            );

            for (uint256 i = 0; i < users.length; i++) {
                wstethBalances[i] = IERC20(deployParams.wsteth).balanceOf(
                    users[i]
                );
                expectedWithdrawalAmounts[i] = FullMath.mulDiv(
                    setup.vault.withdrawalRequest(users[i]).lpAmount,
                    IWSteth(deployParams.wsteth).getWstETHByStETH(totalValue),
                    setup.vault.totalSupply()
                );
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            for (uint256 i = 0; i < users.length; i++) {
                uint256 currentWstethBalance = IERC20(deployParams.wsteth)
                    .balanceOf(users[i]);
                assertApproxEqAbs(
                    currentWstethBalance,
                    wstethBalances[i] + expectedWithdrawalAmounts[i],
                    MAX_ERROR_DEPOSIT
                );
            }

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
            assertEq(
                totalSupplyBeforeWithdrawals,
                setup.vault.totalSupply() + burnedTotalSupply
            );
        }

        // nothing to withdraw
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 amount = setup.vault.balanceOf(user);
            assertEq(amount, 0, "Non-zero amounts");
        }

        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();
        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertLe(baseTvlInit[i], baseTvlAfter[i]);
            assertGe(
                baseTvlInit[i] + users.length * MAX_ERROR_DEPOSIT,
                baseTvlAfter[i]
            );
        }
    }
}
