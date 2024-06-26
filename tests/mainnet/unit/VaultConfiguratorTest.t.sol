// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    uint256 public constant DELAY = 365 days;

    address public immutable admin = address(bytes20(keccak256("vault-admin")));

    function testConstructor() external {
        VaultConfigurator configurator;

        configurator = new VaultConfigurator();
        assertEq(configurator.vault(), address(this));

        vm.prank(address(0));
        configurator = new VaultConfigurator();
        assertEq(configurator.vault(), address(0));

        VaultMock vault = new VaultMock(admin);
        configurator = vault.configurator();

        assertNotEq(address(vault), address(0));
        assertNotEq(address(configurator), address(0));

        assertEq(configurator.MAX_DELAY(), 365 days);
        assertEq(configurator.MAX_WITHDRAWAL_FEE(), 50_000_000);
        assertEq(configurator.vault(), address(vault));
    }

    uint256 public validValue;
    uint256 public invalidValue;
    bytes public expectedError;
    uint256 public initialValue;

    address public validValueAddress;
    address public validValueAddress2;
    address public invalidValueAddress;
    bytes public expectedErrorAddress;
    address public initialValueAddress;

    function testBaseDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.baseDelay,
            configurator.stageBaseDelay,
            configurator.commitBaseDelay,
            configurator.rollbackStagedBaseDelay
        );
    }

    function testDepositCallbackDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.depositCallbackDelay,
            configurator.stageDepositCallbackDelay,
            configurator.commitDepositCallbackDelay,
            configurator.rollbackStagedDepositCallbackDelay
        );
    }

    function testWithdrawalCallbackDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.withdrawalCallbackDelay,
            configurator.stageWithdrawalCallbackDelay,
            configurator.commitWithdrawalCallbackDelay,
            configurator.rollbackStagedWithdrawalCallbackDelay
        );
    }

    function testMaximalTotalSupplyDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.maximalTotalSupplyDelay,
            configurator.stageMaximalTotalSupplyDelay,
            configurator.commitMaximalTotalSupplyDelay,
            configurator.rollbackStagedMaximalTotalSupplyDelay
        );
    }

    function testIsDepositLockedDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.isDepositLockedDelay,
            configurator.stageDepositsLockedDelay,
            configurator.commitDepositsLockedDelay,
            configurator.rollbackStagedDepositsLockedDelay
        );
    }

    function testAreTransfersLockedDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.areTransfersLockedDelay,
            configurator.stageTransfersLockedDelay,
            configurator.commitTransfersLockedDelay,
            configurator.rollbackStagedTransfersLockedDelay
        );
    }

    function testIsDelegateModuleApprovedDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.delegateModuleApprovalDelay,
            configurator.stageDelegateModuleApprovalDelay,
            configurator.commitDelegateModuleApprovalDelay,
            configurator.rollbackStagedDelegateModuleApprovalDelay
        );
    }

    function testRatiosOracleDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.ratiosOracleDelay,
            configurator.stageRatiosOracleDelay,
            configurator.commitRatiosOracleDelay,
            configurator.rollbackStagedRatiosOracleDelay
        );
    }

    function testPriceOracleDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.priceOracleDelay,
            configurator.stagePriceOracleDelay,
            configurator.commitPriceOracleDelay,
            configurator.rollbackStagedPriceOracleDelay
        );
    }

    function testValidatorDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.validatorDelay,
            configurator.stageValidatorDelay,
            configurator.commitValidatorDelay,
            configurator.rollbackStagedValidatorDelay
        );
    }

    function testEmergencyWithdrawalDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.emergencyWithdrawalDelay,
            configurator.stageEmergencyWithdrawalDelay,
            configurator.commitEmergencyWithdrawalDelay,
            configurator.rollbackStagedEmergencyWithdrawalDelay
        );
    }

    function testWithdrawalFeeD9Delay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1 days;
        invalidValue = DELAY + 1;
        expectedError = abi.encodeWithSignature("InvalidDelay()");
        initialValue = 0;
        _runTest(
            configurator.baseDelay,
            configurator.withdrawalFeeD9Delay,
            configurator.stageWithdrawalFeeD9Delay,
            configurator.commitWithdrawalFeeD9Delay,
            configurator.rollbackStagedWithdrawalFeeD9Delay
        );
    }

    /// VALUES

    function testWithdrawalFeeD9WithoutDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValue = 1e7;
        invalidValue = configurator.MAX_WITHDRAWAL_FEE() + 1;
        expectedError = abi.encodeWithSignature("InvalidWithdrawalFee()");
        initialValue = 0;
        _runTest(
            configurator.withdrawalFeeD9Delay,
            configurator.withdrawalFeeD9,
            configurator.stageWithdrawalFeeD9,
            configurator.commitWithdrawalFeeD9,
            configurator.rollbackStagedWithdrawalFeeD9
        );
    }

    function testWithdrawalFeeD9WithDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        vm.startPrank(admin);
        configurator.stageWithdrawalFeeD9Delay(1 days);
        configurator.commitWithdrawalFeeD9Delay();
        vm.stopPrank();

        validValue = 1e7;
        invalidValue = configurator.MAX_WITHDRAWAL_FEE() + 1;
        expectedError = abi.encodeWithSignature("InvalidWithdrawalFee()");
        initialValue = 0;
        _runTest(
            configurator.withdrawalFeeD9Delay,
            configurator.withdrawalFeeD9,
            configurator.stageWithdrawalFeeD9,
            configurator.commitWithdrawalFeeD9,
            configurator.rollbackStagedWithdrawalFeeD9
        );
    }

    function testMaximalTotalSupplyWithoutDelay() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        vault.setCoef(1e9);
        vault.deposit(address(vault), new uint256[](0), 1 ether, 0);
        validValue = 1000 ether;
        invalidValue = 0 ether;
        expectedError = abi.encodeWithSignature("InvalidTotalSupply()");
        initialValue = 0 ether;
        _runTest(
            configurator.maximalTotalSupplyDelay,
            configurator.maximalTotalSupply,
            configurator.stageMaximalTotalSupply,
            configurator.commitMaximalTotalSupply,
            configurator.rollbackStagedMaximalTotalSupply
        );
    }

    function testDepositCallback() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValueAddress = address(1);
        validValueAddress2 = address(2);
        invalidValueAddress = address(type(uint160).max);
        expectedError = new bytes(0);
        initialValueAddress = address(0);
        _runTest(
            configurator.depositCallbackDelay,
            configurator.depositCallback,
            configurator.stageDepositCallback,
            configurator.commitDepositCallback,
            configurator.rollbackStagedDepositCallback
        );
    }

    function testWithdrawalCallback() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValueAddress = address(1);
        validValueAddress2 = address(2);
        invalidValueAddress = address(type(uint160).max);
        expectedError = new bytes(0);
        initialValueAddress = address(0);
        _runTest(
            configurator.withdrawalCallbackDelay,
            configurator.withdrawalCallback,
            configurator.stageWithdrawalCallback,
            configurator.commitWithdrawalCallback,
            configurator.rollbackStagedWithdrawalCallback
        );
    }

    function testRatiosOracle() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValueAddress = address(1);
        validValueAddress2 = address(2);
        invalidValueAddress = address(0);
        expectedError = abi.encodeWithSignature("AddressZero()");
        initialValueAddress = address(0);
        _runTest(
            configurator.ratiosOracleDelay,
            configurator.ratiosOracle,
            configurator.stageRatiosOracle,
            configurator.commitRatiosOracle,
            configurator.rollbackStagedRatiosOracle
        );
    }

    function testPriceOracle() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValueAddress = address(1);
        validValueAddress2 = address(2);
        invalidValueAddress = address(0);
        expectedError = abi.encodeWithSignature("AddressZero()");
        initialValueAddress = address(0);
        _runTest(
            configurator.priceOracleDelay,
            configurator.priceOracle,
            configurator.stagePriceOracle,
            configurator.commitPriceOracle,
            configurator.rollbackStagedPriceOracle
        );
    }

    function testValidator() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        validValueAddress = address(1);
        validValueAddress2 = address(2);
        invalidValueAddress = address(0);
        expectedError = abi.encodeWithSignature("AddressZero()");
        initialValueAddress = address(0);
        _runTest(
            configurator.validatorDelay,
            configurator.validator,
            configurator.stageValidator,
            configurator.commitValidator,
            configurator.rollbackStagedValidator
        );
    }

    function testIsDelegateModuleApproved() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        key = address(123);
        expectedError = abi.encodeWithSignature("AddressZero()");

        _runTestMapping(
            configurator.delegateModuleApprovalDelay,
            configurator.isDelegateModuleApproved,
            configurator.stageDelegateModuleApproval,
            configurator.commitDelegateModuleApproval,
            configurator.rollbackStagedDelegateModuleApproval,
            configurator.revokeDelegateModuleApproval
        );
    }

    bool public validValueBool;
    bool public initialValueBool;

    function testAreTransfersLocked() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();
        executor = admin;
        initialValueBool = false;
        validValueBool = true;
        _runTest(
            configurator.areTransfersLockedDelay,
            configurator.areTransfersLocked,
            configurator.stageTransfersLock,
            configurator.commitTransfersLock,
            configurator.rollbackStagedTransfersLock
        );
    }

    function testIsDepositLockedOnBehalfOfAdmin() external {
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        executor = admin;
        expectedError = abi.encodeWithSignature("AddressZero()");

        _runTest(
            configurator.isDepositLockedDelay,
            configurator.isDepositLocked,
            configurator.stageDepositsLock,
            configurator.commitDepositsLock,
            configurator.rollbackStagedDepositsLock,
            configurator.revokeDepositsLock
        );
    }

    function testIsDepositLockedOnBehalfOfOperator() external {
        VaultMock vault = new VaultMock(admin);

        bytes32 adminRole = vault.ADMIN_ROLE();
        vm.prank(admin);
        vault.renounceRole(adminRole, admin);

        executor = admin;
        VaultConfigurator configurator = vault.configurator();

        expectedError = abi.encodeWithSignature("AddressZero()");

        _runTest(
            configurator.isDepositLockedDelay,
            configurator.isDepositLocked,
            configurator.stageDepositsLock,
            configurator.commitDepositsLock,
            configurator.rollbackStagedDepositsLock,
            configurator.revokeDepositsLock
        );
    }

    function _runTest(
        function() external view returns (uint256) delay,
        function() external view returns (uint256) value,
        function(uint256) external stageFunction,
        function() external commitFunction,
        function() external rollbackFunction
    ) private {
        address randomUser = address(bytes20(keccak256("random-user")));
        vm.startPrank(randomUser);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        stageFunction(validValue);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        commitFunction();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        rollbackFunction();

        vm.stopPrank();
        vm.startPrank(admin);

        assertEq(value(), initialValue);

        if (invalidValue != type(uint256).max) {
            vm.expectRevert(expectedError);
            stageFunction(invalidValue);
        }

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        stageFunction(validValue);

        uint256 delay_ = delay();
        if (delay_ != 0) {
            vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
            commitFunction();
            skip(delay_);
        }

        commitFunction();

        assertEq(value(), validValue);

        if (initialValue == invalidValue) {
            initialValue = validValue;
        }
        stageFunction(initialValue);

        delay_ = delay();
        if (delay_ != 0) {
            skip(delay_);
        }

        rollbackFunction();
        assertEq(value(), validValue);

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        assertEq(value(), validValue);

        vm.stopPrank();
    }

    function _runTest(
        function() external view returns (uint256) delay,
        function() external view returns (bool) value,
        function(bool) external stageFunction,
        function() external commitFunction,
        function() external rollbackFunction
    ) private {
        address randomUser = address(bytes20(keccak256("random-user")));
        vm.startPrank(randomUser);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        stageFunction(true);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        stageFunction(false);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        commitFunction();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        rollbackFunction();

        vm.stopPrank();
        vm.startPrank(admin);

        assertEq(value(), initialValueBool);

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        stageFunction(validValueBool);

        uint256 delay_ = delay();
        if (delay_ != 0) {
            vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
            commitFunction();
            skip(delay_);
        }

        commitFunction();

        assertEq(value(), validValueBool);

        stageFunction(initialValueBool);

        delay_ = delay();
        if (delay_ != 0) {
            skip(delay_);
        }

        rollbackFunction();
        assertEq(value(), validValueBool);

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        assertEq(value(), validValueBool);

        vm.stopPrank();
    }

    function _runTest(
        function() external view returns (uint256) delay,
        function() external view returns (address) value,
        function(address) external stageFunction,
        function() external commitFunction,
        function() external rollbackFunction
    ) private {
        address randomUser = address(bytes20(keccak256("random-user")));
        vm.startPrank(randomUser);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        stageFunction(validValueAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        commitFunction();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        rollbackFunction();

        vm.stopPrank();
        vm.startPrank(admin);

        assertEq(value(), initialValueAddress);

        if (invalidValueAddress != address(type(uint160).max)) {
            vm.expectRevert(expectedError);
            stageFunction(invalidValueAddress);
        }

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        stageFunction(validValueAddress);

        uint256 delay_ = delay();
        if (delay_ != 0) {
            vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
            commitFunction();
            skip(delay_);
        }

        commitFunction();

        assertEq(value(), validValueAddress);

        stageFunction(validValueAddress2);

        delay_ = delay();
        if (delay_ != 0) {
            skip(delay_);
        }

        rollbackFunction();
        assertEq(value(), validValueAddress);

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        assertEq(value(), validValueAddress);

        vm.stopPrank();
    }

    address public key;

    function _runTestMapping(
        function() external view returns (uint256) delay,
        function(address) external view returns (bool) value,
        function(address) external stageFunction,
        function(address) external commitFunction,
        function(address) external rollbackFunction,
        function(address) external revokeFunction
    ) private {
        address randomUser = address(bytes20(keccak256("random-user")));
        vm.startPrank(randomUser);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        stageFunction(key);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        commitFunction(key);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        rollbackFunction(key);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        revokeFunction(key);

        vm.stopPrank();
        vm.startPrank(admin);

        assertFalse(value(key));

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction(key);

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        stageFunction(address(0));

        stageFunction(key);

        uint256 delay_ = delay();
        if (delay_ != 0) {
            vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
            commitFunction(key);
            skip(delay_);
        }

        commitFunction(key);

        assertTrue(value(key));

        revokeFunction(key);

        assertFalse(value(key));

        stageFunction(key);

        delay_ = delay();
        if (delay_ != 0) {
            skip(delay_);
        }

        rollbackFunction(key);
        assertFalse(value(key));

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction(key);

        assertFalse(value(key));

        vm.stopPrank();
    }

    address public executor;

    function _runTest(
        function() external view returns (uint256) delay,
        function() external view returns (bool) value,
        function() external stageFunction,
        function() external commitFunction,
        function() external rollbackFunction,
        function() external revokeFunction
    ) private {
        address randomUser = address(bytes20(keccak256("random-user")));
        vm.startPrank(randomUser);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        stageFunction();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        commitFunction();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        rollbackFunction();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        revokeFunction();

        vm.stopPrank();
        vm.startPrank(executor);

        assertFalse(value());

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        stageFunction();

        uint256 delay_ = delay();
        if (delay_ != 0) {
            vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
            commitFunction();
            skip(delay_);
        }

        commitFunction();

        assertTrue(value());

        revokeFunction();

        assertFalse(value());

        stageFunction();

        delay_ = delay();
        if (delay_ != 0) {
            skip(delay_);
        }

        rollbackFunction();
        assertFalse(value());

        vm.expectRevert(abi.encodeWithSignature("InvalidTimestamp()"));
        commitFunction();

        assertFalse(value());

        vm.stopPrank();
    }

    bytes32 public constant CONFIGURATOR_BASE_DELAY_SLOT =
        bytes32(uint256(0x1));
    bytes32 public constant CONFIGURATOR_DEPOSIT_CALLBACK_DELAY_SLOT =
        bytes32(uint256(0x4));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_CALLBACK_DELAY_SLOT =
        bytes32(uint256(0x7));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_FEE_D9_DELAY_SLOT =
        bytes32(uint256(0xa));
    bytes32 public constant CONFIGURATOR_MAXIMAL_TOTAL_SUPPLY_DELAY_SLOT =
        bytes32(uint256(0xd));
    bytes32 public constant CONFIGURATOR_IS_DEPOSIT_LOCKED_DELAY_SLOT =
        bytes32(uint256(0x10));
    bytes32 public constant CONFIGURATOR_ARE_TRANSFERS_LOCKED_DELAY_SLOT =
        bytes32(uint256(0x13));
    bytes32
        public constant CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_DELAY_SLOT =
        bytes32(uint256(0x16));
    bytes32 public constant CONFIGURATOR_RATIOS_ORACLE_DELAY_SLOT =
        bytes32(uint256(0x19));
    bytes32 public constant CONFIGURATOR_PRICE_ORACLE_DELAY_SLOT =
        bytes32(uint256(0x1c));
    bytes32 public constant CONFIGURATOR_VALIDATOR_DELAY_SLOT =
        bytes32(uint256(0x1f));
    bytes32 public constant CONFIGURATOR_EMERGENCY_WITHDRAWAL_DELAY_SLOT =
        bytes32(uint256(0x22));
    bytes32 public constant CONFIGURATOR_DEPOSIT_CALLBACK_SLOT =
        bytes32(uint256(0x25));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_CALLBACK_SLOT =
        bytes32(uint256(0x28));
    bytes32 public constant CONFIGURATOR_WITHDRAWAL_FEE_D9_SLOT =
        bytes32(uint256(0x2b));
    bytes32 public constant CONFIGURATOR_MAXIMAL_TOTAL_SUPPLY_SLOT =
        bytes32(uint256(0x2e));
    bytes32 public constant CONFIGURATOR_IS_DEPOSIT_LOCKED_SLOT =
        bytes32(uint256(0x31));
    bytes32 public constant CONFIGURATOR_ARE_TRANSFERS_LOCKED_SLOT =
        bytes32(uint256(0x34));
    bytes32 public constant CONFIGURATOR_RATIOS_ORACLE_SLOT =
        bytes32(uint256(0x37));
    bytes32 public constant CONFIGURATOR_PRICE_ORACLE_SLOT =
        bytes32(uint256(0x3a));
    bytes32 public constant CONFIGURATOR_VALIDATOR_SLOT =
        bytes32(uint256(0x3d));
    bytes32 public constant CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_SLOT =
        bytes32(uint256(0x40));

    function getDataAt(
        VaultConfigurator configurator,
        bytes32 slot
    ) public view returns (IVaultConfigurator.Data memory d) {
        d.value = uint256(vm.load(address(configurator), slot));
        d.stagedValue = uint256(
            vm.load(address(configurator), bytes32(uint256(slot) + 1))
        );
        d.stageTimestamp = uint256(
            vm.load(address(configurator), bytes32(uint256(slot) + 2))
        );
    }

    function testUintParamsEvents() external {
        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        function(uint256) external[14] memory stageDelayFunctions = [
            configurator.stageBaseDelay,
            configurator.stageDepositCallbackDelay,
            configurator.stageWithdrawalCallbackDelay,
            configurator.stageWithdrawalFeeD9Delay,
            configurator.stageMaximalTotalSupplyDelay,
            configurator.stageDepositsLockedDelay,
            configurator.stageTransfersLockedDelay,
            configurator.stageDelegateModuleApprovalDelay,
            configurator.stageRatiosOracleDelay,
            configurator.stagePriceOracleDelay,
            configurator.stageValidatorDelay,
            configurator.stageEmergencyWithdrawalDelay,
            configurator.stageWithdrawalFeeD9,
            configurator.stageMaximalTotalSupply
        ];

        function() external[14] memory commitDelayFunctions = [
            configurator.commitBaseDelay,
            configurator.commitDepositCallbackDelay,
            configurator.commitWithdrawalCallbackDelay,
            configurator.commitWithdrawalFeeD9Delay,
            configurator.commitMaximalTotalSupplyDelay,
            configurator.commitDepositsLockedDelay,
            configurator.commitTransfersLockedDelay,
            configurator.commitDelegateModuleApprovalDelay,
            configurator.commitRatiosOracleDelay,
            configurator.commitPriceOracleDelay,
            configurator.commitValidatorDelay,
            configurator.commitEmergencyWithdrawalDelay,
            configurator.commitWithdrawalFeeD9,
            configurator.commitMaximalTotalSupply
        ];

        function() external[14] memory rollbackDelayFunctions = [
            configurator.rollbackStagedBaseDelay,
            configurator.rollbackStagedDepositCallbackDelay,
            configurator.rollbackStagedWithdrawalCallbackDelay,
            configurator.rollbackStagedWithdrawalFeeD9Delay,
            configurator.rollbackStagedMaximalTotalSupplyDelay,
            configurator.rollbackStagedDepositsLockedDelay,
            configurator.rollbackStagedTransfersLockedDelay,
            configurator.rollbackStagedDelegateModuleApprovalDelay,
            configurator.rollbackStagedRatiosOracleDelay,
            configurator.rollbackStagedPriceOracleDelay,
            configurator.rollbackStagedValidatorDelay,
            configurator.rollbackStagedEmergencyWithdrawalDelay,
            configurator.rollbackStagedWithdrawalFeeD9,
            configurator.rollbackStagedMaximalTotalSupply
        ];

        bytes32[14] memory correspondingSlots = [
            CONFIGURATOR_BASE_DELAY_SLOT,
            CONFIGURATOR_DEPOSIT_CALLBACK_DELAY_SLOT,
            CONFIGURATOR_WITHDRAWAL_CALLBACK_DELAY_SLOT,
            CONFIGURATOR_WITHDRAWAL_FEE_D9_DELAY_SLOT,
            CONFIGURATOR_MAXIMAL_TOTAL_SUPPLY_DELAY_SLOT,
            CONFIGURATOR_IS_DEPOSIT_LOCKED_DELAY_SLOT,
            CONFIGURATOR_ARE_TRANSFERS_LOCKED_DELAY_SLOT,
            CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_DELAY_SLOT,
            CONFIGURATOR_RATIOS_ORACLE_DELAY_SLOT,
            CONFIGURATOR_PRICE_ORACLE_DELAY_SLOT,
            CONFIGURATOR_VALIDATOR_DELAY_SLOT,
            CONFIGURATOR_EMERGENCY_WITHDRAWAL_DELAY_SLOT,
            CONFIGURATOR_WITHDRAWAL_FEE_D9_SLOT,
            CONFIGURATOR_MAXIMAL_TOTAL_SUPPLY_SLOT
        ];

        uint256 maxDelay = 2 days;
        uint256 firstStageValue = 1 days + 12 hours;
        uint256 initialUintValue = 0 seconds;
        uint256 newStageValue = 1 days + 10 hours;

        IVaultConfigurator.Data memory d;

        uint256 lastTimestamp = block.timestamp;

        for (uint256 i = 0; i < correspondingSlots.length; i++) {
            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                firstStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](firstStageValue);

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                firstStageValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Rollback(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                block.timestamp
            );

            rollbackDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Rollback: Value should be 0");
            assertEq(d.stagedValue, 0, "Rollback: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Rollback: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                firstStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](firstStageValue);

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                firstStageValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                firstStageValue,
                "Commit: Value should be firstStageValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: newStageValue,
                    value: firstStageValue
                }),
                newStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](newStageValue);

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                firstStageValue,
                "Stage: Value should be firstStageValue"
            );
            assertEq(
                d.stagedValue,
                newStageValue,
                "Stage: Staged value should be newStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: newStageValue,
                    value: firstStageValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                newStageValue,
                "Commit: Value should be newStageValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);
        }
    }

    function testAddressParamsEvents() external {
        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        function(address) external[5] memory stageDelayFunctions = [
            configurator.stageDepositCallback,
            configurator.stageWithdrawalCallback,
            configurator.stageRatiosOracle,
            configurator.stagePriceOracle,
            configurator.stageValidator
        ];

        function() external[5] memory commitDelayFunctions = [
            configurator.commitDepositCallback,
            configurator.commitWithdrawalCallback,
            configurator.commitRatiosOracle,
            configurator.commitPriceOracle,
            configurator.commitValidator
        ];

        function() external[5] memory rollbackDelayFunctions = [
            configurator.rollbackStagedDepositCallback,
            configurator.rollbackStagedWithdrawalCallback,
            configurator.rollbackStagedRatiosOracle,
            configurator.rollbackStagedPriceOracle,
            configurator.rollbackStagedValidator
        ];

        bytes32[5] memory correspondingSlots = [
            CONFIGURATOR_DEPOSIT_CALLBACK_SLOT,
            CONFIGURATOR_WITHDRAWAL_CALLBACK_SLOT,
            CONFIGURATOR_RATIOS_ORACLE_SLOT,
            CONFIGURATOR_PRICE_ORACLE_SLOT,
            CONFIGURATOR_VALIDATOR_SLOT
        ];

        uint256 maxDelay = 2 days;
        uint256 firstStageValue = 1 days + 12 hours;
        uint256 initialUintValue = 0 seconds;
        uint256 newStageValue = 1 days + 10 hours;

        IVaultConfigurator.Data memory d;

        uint256 lastTimestamp = block.timestamp;

        for (uint256 i = 0; i < correspondingSlots.length; i++) {
            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                firstStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](address(uint160(firstStageValue)));

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                firstStageValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Rollback(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                block.timestamp
            );

            rollbackDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Rollback: Value should be 0");
            assertEq(d.stagedValue, 0, "Rollback: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Rollback: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                firstStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](address(uint160(firstStageValue)));

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                firstStageValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                firstStageValue,
                "Commit: Value should be firstStageValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: newStageValue,
                    value: firstStageValue
                }),
                newStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](address(uint160(newStageValue)));

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                firstStageValue,
                "Stage: Value should be firstStageValue"
            );
            assertEq(
                d.stagedValue,
                newStageValue,
                "Stage: Staged value should be newStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: newStageValue,
                    value: firstStageValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                newStageValue,
                "Commit: Value should be newStageValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);
        }
    }

    function testBoolParamsEvents() external {
        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        function(bool) external[1] memory stageDelayFunctions = [
            configurator.stageTransfersLock
        ];

        function() external[1] memory commitDelayFunctions = [
            configurator.commitTransfersLock
        ];

        bytes32[1] memory correspondingSlots = [
            CONFIGURATOR_ARE_TRANSFERS_LOCKED_SLOT
        ];

        uint256 maxDelay = 2 days;
        uint256 firstStageValue = 1;
        uint256 initialUintValue = 0;
        uint256 newStageValue = 0;

        IVaultConfigurator.Data memory d;

        uint256 lastTimestamp = block.timestamp;

        for (uint256 i = 0; i < correspondingSlots.length; i++) {
            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                firstStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](firstStageValue == 1 ? true : false);

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                firstStageValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                firstStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](firstStageValue == 1 ? true : false);

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                firstStageValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: firstStageValue,
                    value: initialUintValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                firstStageValue,
                "Commit: Value should be firstStageValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: newStageValue,
                    value: firstStageValue
                }),
                newStageValue,
                block.timestamp
            );

            stageDelayFunctions[i](newStageValue == 1 ? true : false);

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                firstStageValue,
                "Stage: Value should be firstStageValue"
            );
            assertEq(
                d.stagedValue,
                newStageValue,
                "Stage: Staged value should be newStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: newStageValue,
                    value: firstStageValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                newStageValue,
                "Commit: Value should be newStageValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);
        }
    }

    function testIsDepositLockedEvents() external {
        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        function() external[1] memory stageDelayFunctions = [
            configurator.stageDepositsLock
        ];

        function() external[1] memory revokeDelayFunctions = [
            configurator.revokeDepositsLock
        ];

        function() external[1] memory rollbackDelayFunctions = [
            configurator.rollbackStagedDepositsLock
        ];

        function() external[1] memory commitDelayFunctions = [
            configurator.commitDepositsLock
        ];

        bytes32[1] memory correspondingSlots = [
            CONFIGURATOR_IS_DEPOSIT_LOCKED_SLOT
        ];

        uint256 maxDelay = 2 days;
        uint256 stagedValue = 1;
        uint256 valueAfterRollback = 0;
        uint256 valueAfterRevoke = 0;
        uint256 initialSlotValue = 0;

        IVaultConfigurator.Data memory d;

        uint256 lastTimestamp = block.timestamp;

        for (uint256 i = 0; i < correspondingSlots.length; i++) {
            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                stagedValue,
                block.timestamp
            );

            stageDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                stagedValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            revokeDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                valueAfterRevoke,
                "Revoke: Value should be valueAfterRevoke"
            );
            assertEq(
                d.stagedValue,
                stagedValue,
                "Revoke: Staged value should be stagedValue"
            );
            assertEq(
                d.stageTimestamp,
                lastTimestamp,
                "Revoke: Stage timestamp should be lastTimestamp"
            );

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                block.timestamp
            );

            commitDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                stagedValue,
                "Commit: Value should be stagedValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            revokeDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(
                d.value,
                valueAfterRevoke,
                "Revoke: Value should be valueAfterRevoke"
            );
            assertEq(d.stagedValue, 0, "Revoke: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Revoke: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                stagedValue,
                block.timestamp
            );

            stageDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                stagedValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Rollback(
                correspondingSlots[i],
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                block.timestamp
            );

            rollbackDelayFunctions[i]();

            d = getDataAt(configurator, correspondingSlots[i]);
            assertEq(d.value, 0, "Rollback: Value should be 0");
            assertEq(
                d.stagedValue,
                valueAfterRollback,
                "Rollback: Staged value should be valueAfterRollback"
            );
            assertEq(
                d.stageTimestamp,
                0,
                "Rollback: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);
        }
    }

    function testDelegateModuleApprovalsEvents() external {
        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);
        VaultConfigurator configurator = vault.configurator();

        address[5] memory delegateModules = [
            address(1),
            address(2),
            address(3),
            address(4),
            address(5)
        ];

        uint256 maxDelay = 2 days;
        uint256 stagedValue = 1;
        uint256 valueAfterRollback = 0;
        uint256 valueAfterRevoke = 0;
        uint256 initialSlotValue = 0;

        IVaultConfigurator.Data memory d;

        uint256 lastTimestamp = block.timestamp;

        for (uint256 i = 0; i < delegateModules.length; i++) {
            bytes32 expectedSlot = keccak256(
                abi.encode(
                    delegateModules[i],
                    CONFIGURATOR_IS_DELEGATE_MODULE_APPROVED_SLOT
                )
            );

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                expectedSlot,
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                stagedValue,
                block.timestamp
            );

            configurator.stageDelegateModuleApproval(delegateModules[i]);

            d = getDataAt(configurator, expectedSlot);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                stagedValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            configurator.revokeDelegateModuleApproval(delegateModules[i]);

            d = getDataAt(configurator, expectedSlot);
            assertEq(
                d.value,
                valueAfterRevoke,
                "Revoke: Value should be valueAfterRevoke"
            );
            assertEq(
                d.stagedValue,
                stagedValue,
                "Revoke: Staged value should be stagedValue"
            );
            assertEq(
                d.stageTimestamp,
                lastTimestamp,
                "Revoke: Stage timestamp should be lastTimestamp"
            );

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Commit(
                expectedSlot,
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                block.timestamp
            );

            configurator.commitDelegateModuleApproval(delegateModules[i]);

            d = getDataAt(configurator, expectedSlot);
            assertEq(
                d.value,
                stagedValue,
                "Commit: Value should be stagedValue"
            );
            assertEq(d.stagedValue, 0, "Commit: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Commit: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            configurator.revokeDelegateModuleApproval(delegateModules[i]);

            d = getDataAt(configurator, expectedSlot);
            assertEq(
                d.value,
                valueAfterRevoke,
                "Revoke: Value should be valueAfterRevoke"
            );
            assertEq(d.stagedValue, 0, "Revoke: Staged value should be 0");
            assertEq(
                d.stageTimestamp,
                0,
                "Revoke: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Stage(
                expectedSlot,
                IVaultConfigurator.Data({
                    stageTimestamp: block.timestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                stagedValue,
                block.timestamp
            );

            configurator.stageDelegateModuleApproval(delegateModules[i]);

            d = getDataAt(configurator, expectedSlot);
            assertEq(d.value, 0, "Stage: Value should be 0");
            assertEq(
                d.stagedValue,
                stagedValue,
                "Stage: Staged value should be firstStageValue"
            );
            assertEq(
                d.stageTimestamp,
                block.timestamp,
                "Stage: Stage timestamp should be block.timestamp"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);

            vm.expectEmit(address(configurator));
            emit IVaultConfigurator.Rollback(
                expectedSlot,
                IVaultConfigurator.Data({
                    stageTimestamp: lastTimestamp,
                    stagedValue: stagedValue,
                    value: initialSlotValue
                }),
                block.timestamp
            );

            configurator.rollbackStagedDelegateModuleApproval(
                delegateModules[i]
            );

            d = getDataAt(configurator, expectedSlot);
            assertEq(d.value, 0, "Rollback: Value should be 0");
            assertEq(
                d.stagedValue,
                valueAfterRollback,
                "Rollback: Staged value should be valueAfterRollback"
            );
            assertEq(
                d.stageTimestamp,
                0,
                "Rollback: Stage timestamp should be 0"
            );
            lastTimestamp = block.timestamp;
            skip(maxDelay);
        }
    }
}
