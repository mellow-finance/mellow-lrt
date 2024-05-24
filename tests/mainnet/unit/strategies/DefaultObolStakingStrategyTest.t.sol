// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using stdStorage for StdStorage;
    using SafeERC20 for IERC20;

    address public immutable strategyAdmin =
        address(bytes20(keccak256("strategy-admin")));
    address public immutable admin = address(bytes20(keccak256("vault-admin")));
    address public immutable operator =
        address(bytes20(keccak256("vault-operator")));

    function _convert(
        address[] memory aggregators
    ) private pure returns (IChainlinkOracle.AggregatorData[] memory data) {
        data = new IChainlinkOracle.AggregatorData[](aggregators.length);
        for (uint256 i = 0; i < aggregators.length; i++) {
            data[i] = IChainlinkOracle.AggregatorData({
                aggregatorV3: aggregators[i],
                maxAge: 30 days
            });
        }
    }

    function testConstructor() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        strategy.requireAdmin(strategyAdmin);

        assertEq(address(strategy.vault()), address(vault));
        assertEq(address(strategy.stakingModule()), address(stakingModule));
        assertEq(strategy.maxAllowedRemainder(), 0);
    }

    function testConstructorZeroParams() external {
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            IVault(address(0)),
            IStakingModule(address(0))
        );

        strategy.requireAdmin(strategyAdmin);

        assertEq(address(strategy.vault()), address(0));
        assertEq(address(strategy.stakingModule()), address(0));
        assertEq(strategy.maxAllowedRemainder(), 0);
    }

    function testSetMaxAllowedRemainder() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        assertEq(strategy.maxAllowedRemainder(), 0);
        vm.prank(strategyAdmin);
        strategy.setMaxAllowedRemainder(1 gwei);
        assertEq(strategy.maxAllowedRemainder(), 1 gwei);
    }

    function testSetMaxAllowedRemainderFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.setMaxAllowedRemainder(1 gwei);
    }

    function simplifyDepositSecurityModule(Vm.Wallet memory guardian) public {
        IDepositSecurityModule depositSecurityModule = IDepositSecurityModule(
            Constants.DEPOSIT_SECURITY_MODULE
        );

        vm.startPrank(depositSecurityModule.getOwner());
        depositSecurityModule.setMinDepositBlockDistance(1);
        depositSecurityModule.addGuardian(guardian.addr, 1);
        int256 guardianIndex = depositSecurityModule.getGuardianIndex(
            guardian.addr
        );
        assertTrue(guardianIndex >= 0);
        vm.stopPrank();
    }

    function fetchSignatures(
        Vm.Wallet memory guardian,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 stakingModuleId,
        uint256 nonce
    ) public returns (IDepositSecurityModule.Signature[] memory sigs) {
        bytes32 message = keccak256(
            abi.encodePacked(
                Constants.ATTEST_MESSAGE_PREFIX,
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardian, message);
        sigs = new IDepositSecurityModule.Signature[](1);
        uint8 parity = v - 27;
        sigs[0] = IDepositSecurityModule.Signature({
            r: r,
            vs: bytes32(uint256(s) | (uint256(parity) << 255))
        });
        address signerAddr = ecrecover(message, v, r, s);
        assertEq(signerAddr, guardian.addr);
    }

    function getAllDepositParams(
        uint256 blockNumber,
        Vm.Wallet memory guardian
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
        blockHash = blockhash(blockNumber);
        assertNotEq(bytes32(0), blockHash);
        uint256 stakingModuleId = Constants.SIMPLE_DVT_MODULE_ID;
        depositRoot = IDepositContract(Constants.DEPOSIT_CONTRACT)
            .get_deposit_root();
        nonce = IStakingRouter(Constants.STAKING_ROUTER).getStakingModuleNonce(
            stakingModuleId
        );
        depositCalldata = new bytes(0);
        sigs = fetchSignatures(
            guardian,
            blockNumber,
            blockHash,
            depositRoot,
            stakingModuleId,
            nonce
        );
    }

    function testConvertAndDeposit() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        IVaultConfigurator configurator = vault.configurator();

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        Vm.Wallet memory guardian = vm.createWallet("guardian");
        simplifyDepositSecurityModule(guardian);
        uint256 blockNumber = block.number - 1;
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        ) = getAllDepositParams(blockNumber, guardian);

        vm.startPrank(admin);

        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), address(strategy));

        configurator.stageDelegateModuleApproval(address(stakingModule));
        configurator.commitDelegateModuleApproval(address(stakingModule));

        // lazy option. TODO: add production-accurate integrational tests
        configurator.stageValidator(address(new AllowAllValidator()));
        configurator.commitValidator();

        vm.stopPrank();
        vm.startPrank(strategyAdmin);

        uint256 amount = 1 ether;
        deal(Constants.WETH, address(vault), amount);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), amount);

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0);

        bool success = strategy.convertAndDeposit(
            amount,
            blockNumber,
            blockHash,
            depositRoot,
            nonce,
            depositCalldata,
            sigs
        );

        assertTrue(success);

        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);

        assertNotEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0);

        vm.stopPrank();
    }

    function testConvertAndDepositIsPermissionless() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        IVaultConfigurator configurator = vault.configurator();

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        Vm.Wallet memory guardian = vm.createWallet("guardian");
        simplifyDepositSecurityModule(guardian);
        uint256 blockNumber = block.number - 1;
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        ) = getAllDepositParams(blockNumber, guardian);

        vm.startPrank(admin);

        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), address(strategy));

        configurator.stageDelegateModuleApproval(address(stakingModule));
        configurator.commitDelegateModuleApproval(address(stakingModule));

        configurator.stageValidator(address(new AllowAllValidator()));
        configurator.commitValidator();

        vm.stopPrank();

        uint256 amount = 1 ether;
        deal(Constants.WETH, address(vault), amount);
        strategy.convertAndDeposit(
            amount,
            blockNumber,
            blockHash,
            depositRoot,
            nonce,
            depositCalldata,
            sigs
        );
        vm.stopPrank();
    }

    function testProcessWithdrawals() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        IVaultConfigurator configurator = vault.configurator();

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        vm.startPrank(admin);
        {
            vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
            vault.grantRole(vault.OPERATOR(), address(strategy));

            configurator.stageDelegateModuleApproval(address(stakingModule));
            configurator.commitDelegateModuleApproval(address(stakingModule));

            configurator.stageValidator(address(new AllowAllValidator()));
            configurator.commitValidator();

            configurator.stageMaximalTotalSupply(type(uint256).max);
            configurator.commitMaximalTotalSupply();

            vault.addToken(Constants.WETH);
            vault.addToken(Constants.WSTETH);

            vault.addTvlModule(address(new ERC20TvlModule()));
        }
        {
            ManagedRatiosOracle oracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[1] = 2 ** 96;
            oracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[1] = 0;
            ratiosX96[0] = 2 ** 96;
            oracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(oracle));
            configurator.commitRatiosOracle();
        }

        {
            ChainlinkOracle oracle = new ChainlinkOracle();

            oracle.setBaseToken(address(vault), Constants.WETH);

            address[] memory tokens = new address[](2);
            tokens[0] = Constants.WETH;
            tokens[1] = Constants.WSTETH;
            address[] memory oracles = new address[](2);
            oracles[0] = Constants.WETH_CHAINLINK_ORACLE;
            oracles[1] = address(
                new WStethRatiosAggregatorV3(Constants.WSTETH)
            );
            oracle.setChainlinkOracles(
                address(vault),
                tokens,
                _convert(oracles)
            );

            configurator.stagePriceOracle(address(oracle));
            configurator.commitPriceOracle();
        }

        // initial deposit
        {
            uint256 amount = 1 gwei;
            deal(Constants.WETH, admin, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(address(vault), amounts, amount, type(uint256).max);
        }

        vm.stopPrank();

        vm.startPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 1 ether;
            deal(Constants.WETH, Constants.DEPOSITOR, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max
            );

            vault.registerWithdrawal(
                Constants.DEPOSITOR,
                1 ether,
                new uint256[](2),
                type(uint256).max,
                type(uint256).max,
                false
            );
        }
        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        strategy.setMaxAllowedRemainder(1 gwei);
        {
            address[] memory users = vault.pendingWithdrawers();
            bool[] memory status = strategy.processWithdrawals(users, 0);
            assertEq(status.length, 1);
            assertFalse(status[0]);
            assertEq(
                IERC20(Constants.WETH).balanceOf(address(vault)),
                1 ether + 1 gwei
            );
        }

        {
            bool[] memory status = strategy.processWithdrawals(
                new address[](0),
                0
            );
            assertEq(status.length, 0);
        }

        {
            address[] memory users = vault.pendingWithdrawers();
            (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
                .analyzeRequest(
                    vault.calculateStack(),
                    vault.withdrawalRequest(users[0])
                );

            assertTrue(isProcessingPossible);
            assertFalse(isWithdrawalPossible);

            bool[] memory status = strategy.processWithdrawals(users, 1 ether);
            assertEq(status.length, 1);
            assertTrue(status[0]);
            assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 1 gwei);
            assertTrue(
                IERC20(Constants.WSTETH).balanceOf(Constants.DEPOSITOR) > 0
            );
        }
        vm.stopPrank();
    }

    function testProcessWithdrawalsFailsWithLimitOverflow() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        IVaultConfigurator configurator = vault.configurator();

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        vm.startPrank(admin);
        {
            vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
            vault.grantRole(vault.OPERATOR(), address(strategy));

            configurator.stageDelegateModuleApproval(address(stakingModule));
            configurator.commitDelegateModuleApproval(address(stakingModule));

            configurator.stageValidator(address(new AllowAllValidator()));
            configurator.commitValidator();

            configurator.stageMaximalTotalSupply(type(uint256).max);
            configurator.commitMaximalTotalSupply();

            vault.addToken(Constants.WETH);
            vault.addToken(Constants.WSTETH);

            vault.addTvlModule(address(new ERC20TvlModule()));
        }
        {
            ManagedRatiosOracle oracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[1] = 2 ** 96;
            oracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[1] = 0;
            ratiosX96[0] = 2 ** 96;
            oracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(oracle));
            configurator.commitRatiosOracle();
        }

        {
            ChainlinkOracle oracle = new ChainlinkOracle();

            oracle.setBaseToken(address(vault), Constants.WETH);

            address[] memory tokens = new address[](2);
            tokens[0] = Constants.WETH;
            tokens[1] = Constants.WSTETH;
            address[] memory oracles = new address[](2);
            oracles[0] = Constants.WETH_CHAINLINK_ORACLE;
            oracles[1] = address(
                new WStethRatiosAggregatorV3(Constants.WSTETH)
            );
            oracle.setChainlinkOracles(
                address(vault),
                tokens,
                _convert(oracles)
            );

            configurator.stagePriceOracle(address(oracle));
            configurator.commitPriceOracle();
        }

        // initial deposit
        {
            uint256 amount = 1 gwei;
            deal(Constants.WETH, admin, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(address(vault), amounts, amount, type(uint256).max);
        }

        vm.stopPrank();

        vm.startPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 1 ether;
            deal(Constants.WETH, Constants.DEPOSITOR, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max
            );

            vault.registerWithdrawal(
                Constants.DEPOSITOR,
                1 ether,
                new uint256[](2),
                type(uint256).max,
                type(uint256).max,
                false
            );
        }
        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        {
            address[] memory users = vault.pendingWithdrawers();
            bool[] memory status = strategy.processWithdrawals(users, 0);
            assertEq(status.length, 1);
            assertFalse(status[0]);
            assertEq(
                IERC20(Constants.WETH).balanceOf(address(vault)),
                1 ether + 1 gwei
            );
        }
        {
            address[] memory users = vault.pendingWithdrawers();

            (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
                .analyzeRequest(
                    vault.calculateStack(),
                    vault.withdrawalRequest(users[0])
                );

            assertTrue(isProcessingPossible);
            assertFalse(isWithdrawalPossible);

            vm.expectRevert(abi.encodeWithSignature("LimitOverflow()"));
            strategy.processWithdrawals(users, 1 ether);
        }
        vm.stopPrank();
    }

    function testProcessWithdrawalsWithoutConvertCall() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        IVaultConfigurator configurator = vault.configurator();

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        vm.startPrank(admin);
        {
            vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
            vault.grantRole(vault.OPERATOR(), address(strategy));

            configurator.stageDelegateModuleApproval(address(stakingModule));
            configurator.commitDelegateModuleApproval(address(stakingModule));

            configurator.stageValidator(address(new AllowAllValidator()));
            configurator.commitValidator();

            configurator.stageMaximalTotalSupply(type(uint256).max);
            configurator.commitMaximalTotalSupply();

            vault.addToken(Constants.WETH);
            vault.addToken(Constants.WSTETH);

            vault.addTvlModule(address(new ERC20TvlModule()));
        }
        {
            ManagedRatiosOracle oracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[1] = 2 ** 96;
            oracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[1] = 0;
            ratiosX96[0] = 2 ** 96;
            oracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(oracle));
            configurator.commitRatiosOracle();
        }

        {
            ChainlinkOracle oracle = new ChainlinkOracle();

            oracle.setBaseToken(address(vault), Constants.WETH);

            address[] memory tokens = new address[](2);
            tokens[0] = Constants.WETH;
            tokens[1] = Constants.WSTETH;
            address[] memory oracles = new address[](2);
            oracles[0] = address(new ConstantAggregatorV3(1 ether));
            oracles[1] = address(
                new WStethRatiosAggregatorV3(Constants.WSTETH)
            );
            oracle.setChainlinkOracles(
                address(vault),
                tokens,
                _convert(oracles)
            );

            configurator.stagePriceOracle(address(oracle));
            configurator.commitPriceOracle();
        }

        // initial deposit
        {
            uint256 amount = 1 gwei;
            deal(Constants.WETH, admin, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(address(vault), amounts, amount, type(uint256).max);
        }

        vm.stopPrank();

        vm.startPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 1 ether;
            deal(Constants.WETH, Constants.DEPOSITOR, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max
            );

            vault.registerWithdrawal(
                Constants.DEPOSITOR,
                1 ether,
                new uint256[](2),
                type(uint256).max,
                type(uint256).max,
                false
            );
        }
        vm.stopPrank();
        vm.startPrank(admin);
        {
            (bool success, ) = vault.delegateCall(
                address(stakingModule),
                abi.encodeWithSelector(IStakingModule.convert.selector, 1 ether)
            );
            assertTrue(success);
        }
        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        strategy.setMaxAllowedRemainder(1 gwei);
        {
            address[] memory users = vault.pendingWithdrawers();
            bool[] memory status = strategy.processWithdrawals(users, 0);
            assertEq(status.length, 1);
            assertTrue(status[0]);
            assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 1 wei);
        }
        vm.stopPrank();
    }

    function testProcessWithdrawalsWithoutConvertCall2() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        IVaultConfigurator configurator = vault.configurator();

        StakingModule stakingModule = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        SimpleDVTStakingStrategy strategy = new SimpleDVTStakingStrategy(
            strategyAdmin,
            vault,
            stakingModule
        );

        vm.startPrank(admin);
        {
            vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
            vault.grantRole(vault.OPERATOR(), address(strategy));

            configurator.stageDelegateModuleApproval(address(stakingModule));
            configurator.commitDelegateModuleApproval(address(stakingModule));

            configurator.stageValidator(address(new AllowAllValidator()));
            configurator.commitValidator();

            configurator.stageMaximalTotalSupply(type(uint256).max);
            configurator.commitMaximalTotalSupply();

            vault.addToken(Constants.WETH);
            vault.addToken(Constants.WSTETH);

            vault.addTvlModule(address(new ERC20TvlModule()));
        }
        {
            ManagedRatiosOracle oracle = new ManagedRatiosOracle();
            uint128[] memory ratiosX96 = new uint128[](2);
            ratiosX96[1] = 2 ** 96;
            oracle.updateRatios(address(vault), true, ratiosX96);
            ratiosX96[1] = 0;
            ratiosX96[0] = 2 ** 96;
            oracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(oracle));
            configurator.commitRatiosOracle();
        }

        {
            ChainlinkOracle oracle = new ChainlinkOracle();

            oracle.setBaseToken(address(vault), Constants.WETH);

            address[] memory tokens = new address[](2);
            tokens[0] = Constants.WETH;
            tokens[1] = Constants.WSTETH;
            address[] memory oracles = new address[](2);
            oracles[0] = Constants.WETH_CHAINLINK_ORACLE;
            oracles[1] = address(
                new WStethRatiosAggregatorV3(Constants.WSTETH)
            );
            oracle.setChainlinkOracles(
                address(vault),
                tokens,
                _convert(oracles)
            );

            configurator.stagePriceOracle(address(oracle));
            configurator.commitPriceOracle();
        }

        // initial deposit
        {
            uint256 amount = 1 gwei;
            deal(Constants.WETH, admin, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(address(vault), amounts, amount, type(uint256).max);
        }

        vm.stopPrank();

        vm.startPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 1 ether;
            deal(Constants.WETH, Constants.DEPOSITOR, amount);
            IERC20(Constants.WETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](2);
            amounts[1] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max
            );

            vault.registerWithdrawal(
                Constants.DEPOSITOR,
                1 ether,
                new uint256[](2),
                type(uint256).max,
                type(uint256).max,
                false
            );
        }
        vm.stopPrank();

        vm.startPrank(admin);
        {
            (bool success, ) = vault.delegateCall(
                address(stakingModule),
                abi.encodeWithSelector(IStakingModule.convert.selector, 1 ether)
            );
            assertTrue(success);
        }
        vm.stopPrank();

        vm.startPrank(strategyAdmin);

        deal(Constants.WETH, address(vault), type(uint256).max);
        {
            address[] memory users = vault.pendingWithdrawers();
            vm.expectRevert();
            strategy.processWithdrawals(users, 0);
        }
        vm.stopPrank();
    }
}
