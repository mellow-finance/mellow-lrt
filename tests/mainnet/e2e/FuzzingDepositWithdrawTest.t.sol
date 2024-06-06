// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet/Deploy.s.sol";

contract FuzzingDepositWithdrawTest is DeployScript, Validator, Test {
    using SafeERC20 for IERC20;

    DeployInterfaces.DeployParameters deployParams;
    DeployInterfaces.DeploySetup setup;

    address[] users;
    uint256[] amounts;
    uint256[] lpAmounts;
    uint256 private seed;
    uint256 private constant userCount = 2;

    uint256 public constant MAX_ERROR_DEPOSIT = 4 wei;

    function setUp() public {
        seed = 12345567890;

        bool test = true;

        address curator = DeployConstants.STEAKHOUSE_MULTISIG;
        string memory name = DeployConstants.STEAKHOUSE_VAULT_TEST_NAME;
        string memory symbol = DeployConstants.STEAKHOUSE_VAULT_TEST_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_TEST_DEPLOYER;
        vm.startBroadcast(deployParams.deployer);

        deployParams.proxyAdmin = DeployConstants
            .MELLOW_LIDO_TEST_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_LIDO_TEST_MULTISIG;

        // only for testing purposes
        if (test) {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND_TEST;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY_TEST;
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
        deployParams.timeLockDelay = DeployConstants.TIMELOCK_TEST_DELAY;
// ------------------------------
        deployParams.initializer = Initializer(
            0x8f06BEB555D57F0D20dB817FF138671451084e24
        );
        deployParams.initialImplementation = Vault(
            payable(0x0c3E4E9Ab10DfB52c52171F66eb5C7E05708F77F)
        );
        deployParams.erc20TvlModule = ERC20TvlModule(
            0xCA60f449867c9101Ec80F8C611eaB39afE7bD638
        );
        deployParams.defaultBondModule = DefaultBondModule(
            0x204043f4bda61F719Ad232b4196E1bc4131a3096
        );
        deployParams.defaultBondTvlModule = DefaultBondTvlModule(
            0x48f758bd51555765EBeD4FD01c85554bD0B3c03B
        );
        deployParams.ratiosOracle = ManagedRatiosOracle(
            0x1437DCcA4e1442f20285Fb7C11805E7a965681e2
        );
        deployParams.priceOracle = ChainlinkOracle(
            0xA5046e9379B168AFA154504Cf16853B6a7728436
        );
        deployParams.wethAggregatorV3 = ConstantAggregatorV3(
            0x3C1418499aa69A08DfBCed4243BBA7EB90dE3D09
        );
        deployParams.wstethAggregatorV3 = WStethRatiosAggregatorV3(
            0x773ae8ca45D5701131CA84C58821a39DdAdC709c
        );
        deployParams.defaultProxyImplementation = DefaultProxyImplementation(
            0x538459eeA06A06018C70bf9794e1c7b298694828
        );
// ------------------------------

        deployParams = commonContractsDeploy(deployParams);
        deployParams.curator = curator;
        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;

        (deployParams, setup) = deploy(deployParams);

        validateParameters(deployParams, setup);
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

    function _generateRandomNumber() internal returns (uint256) {
        seed = uint256(
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, seed)
                )
            )
        );
        return seed;
    }

    function _getRandomFraction(uint256 amount) internal returns (uint256) {
        uint16 numerator = uint16(_generateRandomNumber() >> 240);
        uint16 denominator = uint16(_generateRandomNumber() >> 240);
        if (numerator > denominator) {
            (numerator, denominator) = (denominator, numerator);
        }
        return FullMath.mulDiv(amount, numerator, denominator);
    }

    function testFuzz_RandomDeposit_ETH_Withdraw(
        uint64[userCount] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 totalSupplyInit = setup.vault.totalSupply();
        uint256 totalLpAmountUsers;
        seed = seedRandom;
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            amount += (amount < 1000 gwei ? 1000 gwei : 0);
            randomAmounts[i] = amount;
            address depositor = address(uint160(i + 0xffffffffffff));
            users.push() = depositor;
        }

        // initial deposits
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            address depositor = users[i];
            deal(depositor, amount);
            vm.startPrank(depositor);
            uint256 lpAmount = setup.depositWrapper.deposit{value: amount}(
                depositor,
                address(0),
                amount,
                0,
                type(uint256).max
            );
            assertApproxEqAbs(lpAmount, amount, MAX_ERROR_DEPOSIT);
            vm.stopPrank();
            amounts.push() = amount;
            lpAmounts.push() = lpAmount;
            assertEq(lpAmount, IERC20(setup.vault).balanceOf(depositor));
            totalLpAmountUsers += lpAmount;
        }

        uint256 totalSupplyAfterDeposit = setup.vault.totalSupply();
        assertApproxEqAbs(totalLpAmountUsers, totalSupplyAfterDeposit - totalSupplyInit, userCount * MAX_ERROR_DEPOSIT);
        totalLpAmountUsers = 0;

        // first random withdrawals
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = _getRandomFraction(amount);
                if (amountWithdraw == 0) {
                    continue;
                }
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                amounts[i] = amount;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw0 = setup.vault.totalSupply();
            assertApproxEqAbs(totalLpAmountUsers, totalSupplyAfterWithdraw0 - totalSupplyInit, userCount * MAX_ERROR_DEPOSIT);
        }
        totalLpAmountUsers = 0;

        // withdrawal remains
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = amount;
                if (amountWithdraw == 0) {
                    continue;
                }
                console2.log(amount, amountWithdraw);
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
                assertEq(amount, 0);
            }

            assertEq(totalLpAmountUsers, 0);
            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw1 = setup.vault.totalSupply();
            assertEq(totalSupplyAfterWithdraw1, totalSupplyInit);
            
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
               // assertEq(lpAmounts[i], IERC20(DeployConstants.WSTETH).balanceOf(depositor));
            }
        }
        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertApproxEqAbs(baseTvlInit[i], baseTvlAfter[i], userCount * MAX_ERROR_DEPOSIT);
        }
    }

    function testFuzz_RandomDeposit_WETH_Withdraw(
        uint64[userCount] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 totalSupplyInit = setup.vault.totalSupply();
        uint256 totalLpAmountUsers;
        seed = seedRandom;
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            amount += (amount < 1000 gwei ? 1000 gwei : 0);
            randomAmounts[i] = amount;
            address depositor = address(uint160(i + 0xffffffffffff));
            users.push() = depositor;
        }

        // initial deposits
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            address depositor = users[i];
            deal(DeployConstants.WETH, depositor, amount);
            vm.startPrank(depositor);
            IERC20(DeployConstants.WETH).safeIncreaseAllowance(
                address(setup.depositWrapper),
                amount
            );
            uint256 lpAmount = setup.depositWrapper.deposit(
                depositor,
                DeployConstants.WETH,
                amount,
                0,
                type(uint256).max
            );
            vm.stopPrank();
            amounts.push() = amount;
            lpAmounts.push() = lpAmount;
            assertEq(lpAmount, IERC20(setup.vault).balanceOf(depositor));
            totalLpAmountUsers += lpAmount;
        }

        uint256 totalSupplyAfterDeposit = setup.vault.totalSupply();
        assertEq(totalLpAmountUsers, totalSupplyAfterDeposit - totalSupplyInit);
        totalLpAmountUsers = 0;

        // first random withdrawals
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = _getRandomFraction(amount);
                if (amountWithdraw == 0) {
                    continue;
                }
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                amounts[i] = amount;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw0 = setup.vault.totalSupply();
            assertEq(totalLpAmountUsers, totalSupplyAfterWithdraw0 - totalSupplyInit);
        }
        totalLpAmountUsers = 0;

        // withdrawal remains
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = amount;
                if (amountWithdraw == 0) {
                    continue;
                }
                console2.log(amount, amountWithdraw);
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
                assertEq(amount, 0);
            }

            assertEq(totalLpAmountUsers, 0);
            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw1 = setup.vault.totalSupply();
            assertEq(totalSupplyAfterWithdraw1, totalSupplyInit);
            
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
               // assertEq(lpAmounts[i], IERC20(DeployConstants.WSTETH).balanceOf(depositor));
            }
        }
        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertApproxEqAbs(baseTvlInit[i], baseTvlAfter[i], userCount * MAX_ERROR_DEPOSIT);
        }
    }

    function testFuzz_RandomDeposit_WSTETH_Withdraw(
        uint64[userCount] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 totalSupplyInit = setup.vault.totalSupply();
        uint256 totalLpAmountUsers;
        seed = seedRandom;
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            amount += (amount < 1000 gwei ? 1000 gwei : 0);
            randomAmounts[i] = amount;
            address depositor = address(uint160(i + 0xffffffffffff));
            users.push() = depositor;
        }

        // initial deposits
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            address depositor = users[i];
            deal(DeployConstants.WSTETH, depositor, amount);
            vm.startPrank(depositor);
            IERC20(DeployConstants.WSTETH).safeIncreaseAllowance(
                address(setup.depositWrapper),
                amount
            );
            uint256 lpAmount = setup.depositWrapper.deposit(
                depositor,
                DeployConstants.WSTETH,
                amount,
                0,
                type(uint256).max
            );
            vm.stopPrank();
            amounts.push() = lpAmount;
            lpAmounts.push() = lpAmount;
            assertEq(lpAmount, IERC20(setup.vault).balanceOf(depositor));
            totalLpAmountUsers += lpAmount;
        }

        uint256 totalSupplyAfterDeposit = setup.vault.totalSupply();
        assertApproxEqAbs(totalLpAmountUsers, totalSupplyAfterDeposit - totalSupplyInit, userCount * MAX_ERROR_DEPOSIT);
        totalLpAmountUsers = 0;

        // first random withdrawals
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = _getRandomFraction(amount);
                if (amountWithdraw == 0) {
                    continue;
                }
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                amounts[i] = amount;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw0 = setup.vault.totalSupply();
            assertEq(totalLpAmountUsers, totalSupplyAfterWithdraw0 - totalSupplyInit);
        }

        totalLpAmountUsers = 0;

        // withdrawal remains
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = amount;
                if (amountWithdraw == 0) {
                    continue;
                }
                console2.log(amount, amountWithdraw);
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
                assertEq(amount, 0);
            }

        //    assertEq(totalLpAmountUsers, 0);
            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw1 = setup.vault.totalSupply();
            assertEq(totalSupplyAfterWithdraw1, totalSupplyInit);
            
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
               // assertEq(lpAmounts[i], IERC20(DeployConstants.WSTETH).balanceOf(depositor));
            }
        }
        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertApproxEqAbs(baseTvlInit[i], baseTvlAfter[i], userCount * MAX_ERROR_DEPOSIT);
        }
    }

/*    // revert at STETH.balanceOf(anyAddress)
    function testFuzz_RandomDeposit_STETH_Withdraw(
        uint64[userCount] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 totalSupplyInit = setup.vault.totalSupply();
        uint256 totalLpAmountUsers;
        seed = seedRandom;
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            amount += (amount < 1000 gwei ? 1000 gwei : 0);
            randomAmounts[i] = amount;
            address depositor = address(uint160(i + 0xffffffffffff));
            users.push() = depositor;
        }

        // initial deposits
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            address depositor = users[i];
            deal(DeployConstants.STETH, depositor, amount);
            vm.startPrank(depositor);
            IERC20(DeployConstants.STETH).safeIncreaseAllowance(
                address(setup.depositWrapper),
                amount
            );
            uint256 lpAmount = setup.depositWrapper.deposit(
                depositor,
                DeployConstants.STETH,
                amount,
                0,
                type(uint256).max
            );
            vm.stopPrank();
            amounts.push() = amount;
            lpAmounts.push() = lpAmount;
            assertEq(lpAmount, IERC20(setup.vault).balanceOf(depositor));
            totalLpAmountUsers += lpAmount;
        }

        uint256 totalSupplyAfterDeposit = setup.vault.totalSupply();
        assertEq(totalLpAmountUsers, totalSupplyAfterDeposit - totalSupplyInit);
        totalLpAmountUsers = 0;


        // first random withdrawals
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = _getRandomFraction(amount);
                if (amountWithdraw == 0) {
                    continue;
                }
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                amounts[i] = amount;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw0 = setup.vault.totalSupply();
            assertEq(totalLpAmountUsers, totalSupplyAfterWithdraw0 - totalSupplyInit);
        }
        totalLpAmountUsers = 0;

        // withdrawal remains
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = amount;
                if (amountWithdraw == 0) {
                    continue;
                }
                console2.log(amount, amountWithdraw);
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
                assertEq(amount, 0);
            }

            assertEq(totalLpAmountUsers, 0);
            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw1 = setup.vault.totalSupply();
            assertEq(totalSupplyAfterWithdraw1, totalSupplyInit);
            
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
               // assertEq(lpAmounts[i], IERC20(DeployConstants.WSTETH).balanceOf(depositor));
            }
        }
        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertApproxEqAbs(baseTvlInit[i], baseTvlAfter[i], userCount * MAX_ERROR_DEPOSIT);
        }
    } */

    function testFuzz_RandomDeposit_ETH_Emergency_Withdraw(
        uint64[userCount] memory randomAmounts,
        uint160 seedRandom
    ) external {
        (, uint256[] memory baseTvlInit) = setup.vault.baseTvl();
        uint256 totalSupplyInit = setup.vault.totalSupply();
        uint256 totalLpAmountUsers;
        seed = seedRandom;
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            amount += (amount < 1000 gwei ? 1000 gwei : 0);
            randomAmounts[i] = amount;
            address depositor = address(uint160(i + 0xffffffffffff));
            users.push() = depositor;
        }

        // initial deposits
        for (uint160 i = 0; i < userCount; i++) {
            uint64 amount = randomAmounts[i];
            address depositor = users[i];
            deal(depositor, amount);
            vm.startPrank(depositor);
            uint256 lpAmount = setup.depositWrapper.deposit{value: amount}(
                depositor,
                address(0),
                amount,
                0,
                type(uint256).max
            );
            vm.stopPrank();
            amounts.push() = amount;
            lpAmounts.push() = lpAmount;
            assertEq(lpAmount, IERC20(setup.vault).balanceOf(depositor));
            totalLpAmountUsers += lpAmount;
        }

        uint256 totalSupplyAfterDeposit = setup.vault.totalSupply();
        assertEq(totalLpAmountUsers, totalSupplyAfterDeposit - totalSupplyInit);
        totalLpAmountUsers = 0;

        // first random withdrawals
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                uint256 amountWithdraw = _getRandomFraction(amount);
                if (amountWithdraw == 0) {
                    continue;
                }
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amountWithdraw,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                vm.stopPrank();
                amount -= amountWithdraw;
                amounts[i] = amount;
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
            }

            vm.startPrank(deployParams.admin);
            setup.defaultBondStrategy.processAll();
            vm.stopPrank();

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw0 = setup.vault.totalSupply();
            assertEq(totalLpAmountUsers, totalSupplyAfterWithdraw0 - totalSupplyInit);
        }
        totalLpAmountUsers = 0;

        // emergency withdrawal remains
        {
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
                uint256 amount = amounts[i];
                if (amount== 0) {
                    continue;
                }
                vm.startPrank(depositor);
                setup.vault.registerWithdrawal(
                    depositor,
                    amount,
                    new uint256[](1),
                    type(uint256).max,
                    type(uint256).max,
                    false
                );
                uint256[] memory amountWithdraw = new uint256[](2);
                vm.warp(block.timestamp + 91 days);
                amountWithdraw = setup.vault.emergencyWithdraw(amountWithdraw, type(uint256).max);
                vm.stopPrank();
                totalLpAmountUsers += IERC20(setup.vault).balanceOf(depositor);
                console2.log(amountWithdraw[0], amountWithdraw[1]);
                //console2.log("balances", IERC20(DeployConstants.WETH).balanceOf(depositor), IERC20(DeployConstants.WSTETH).balanceOf(depositor));
            }

            assertEq(totalLpAmountUsers, 0);

            address[] memory withdrawers = setup.vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);

            uint256 totalSupplyAfterWithdraw1 = setup.vault.totalSupply();
            assertEq(totalSupplyAfterWithdraw1, totalSupplyInit);
            
            for (uint256 i = 0; i < userCount; i++) {
                address depositor = users[i];
               // assertEq(lpAmounts[i], IERC20(DeployConstants.WSTETH).balanceOf(depositor));
            }
        }
        (, uint256[] memory baseTvlAfter) = setup.vault.baseTvl();

        for (uint256 i = 0; i < baseTvlInit.length; i++) {
            assertApproxEqAbs(baseTvlInit[i], baseTvlAfter[i], userCount * MAX_ERROR_DEPOSIT);
        }
    }
}
