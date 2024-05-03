// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IVaultConfigurator.sol";

import "./utils/DefaultAccessControl.sol";

contract VaultConfigurator is IVaultConfigurator, ReentrancyGuard {
    error AddressZero();
    error Forbidden();

    uint256 public constant MAX_DELAY = 365 days;
    uint256 public constant MAX_WITHDRAWAL_FEE = 5e7; // 5%

    Data private _baseDelay;

    Data private _depositCallbackDelay;
    Data private _withdrawalCallbackDelay;
    Data private _withdrawalFeeD9Delay;
    Data private _maximalTotalSupplyDelay;
    Data private _isDepositsLockedDelay;
    Data private _isDelegateModuleApprovedDelay;
    Data private _ratiosOracleDelay;
    Data private _priceOracleDelay;
    Data private _validatorDelay;
    Data private _emergencyWithdrawalDelay;

    Data private _depositCallback;
    Data private _withdrawalCallback;
    Data private _withdrawalFeeD9;
    Data private _maximalTotalSupply;
    Data private _isDepositsLocked;
    Data private _ratiosOracle;
    Data private _priceOracle;
    Data private _validator;

    mapping(address => Data) private _isDelegateModuleApproved;

    address public immutable vault;

    constructor() {
        vault = msg.sender;
    }

    modifier onlyAdmin() {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        _;
    }

    modifier atLeastOperator() {
        IDefaultAccessControl(vault).requireAtLeastOperator(msg.sender);
        _;
    }

    function _stage(Data storage s, bytes32 value) private {
        s.stageTimestamp = block.timestamp;
        s.stagedValue = value;
    }

    function _commit(Data storage s, Data storage delay) private {
        uint256 timestamp = s.stageTimestamp;
        if (
            timestamp == 0 || block.timestamp - timestamp < uint256(delay.value)
        ) revert InvalidTimestamp();
        s.value = s.stagedValue;
        delete s.stageTimestamp;
        delete s.stagedValue;
    }

    function _rollback(Data storage s) private {
        delete s.stageTimestamp;
        delete s.stagedValue;
    }

    function isDelegateModuleApproved(
        address module
    ) external view returns (bool) {
        return _isDelegateModuleApproved[module].value != bytes32(0);
    }

    function isDepositsLocked() external view returns (bool) {
        return _isDepositsLocked.value != bytes32(0);
    }

    function maximalTotalSupply() external view returns (uint256) {
        return uint256(_maximalTotalSupply.value);
    }

    function depositCallback() external view returns (address) {
        return address(bytes20(_depositCallback.value));
    }

    function withdrawalCallback() external view returns (address) {
        return address(bytes20(_withdrawalCallback.value));
    }

    function withdrawalFeeD9() external view returns (uint256) {
        return uint256(_withdrawalFeeD9.value);
    }

    function stageDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        if (module == address(0)) revert AddressZero();
        _stage(_isDelegateModuleApproved[module], bytes32(uint256(1)));
    }

    function commitDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _commit(
            _isDelegateModuleApproved[module],
            _isDelegateModuleApprovedDelay
        );
    }

    function rollbackStagedDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _rollback(_isDelegateModuleApproved[module]);
    }

    function revokeDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _isDelegateModuleApproved[module].value = bytes32(0);
    }

    function stageDepositsLock() external atLeastOperator nonReentrant {
        _stage(_isDepositsLocked, bytes32(uint256(1)));
    }

    function commitDepositsLock() external atLeastOperator nonReentrant {
        _commit(_isDepositsLocked, _isDepositsLockedDelay);
    }

    function rollbackDepositsLock() external atLeastOperator nonReentrant {
        _rollback(_isDepositsLocked);
    }

    function revokeDepositsLock() external atLeastOperator nonReentrant {
        _isDepositsLocked.value = bytes32(0);
    }

    function stageMaximalTotalSupply(
        uint256 maximalTotalSupply_
    ) external onlyAdmin nonReentrant {
        _stage(_maximalTotalSupply, bytes32(maximalTotalSupply_));
    }

    function commitMaximalTotalSupply() external onlyAdmin nonReentrant {
        _commit(_maximalTotalSupply, _maximalTotalSupplyDelay);
    }

    function rollbackStagedMaximalTotalSupply()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_maximalTotalSupply);
    }

    function stageDepositCallback(
        address callback
    ) external onlyAdmin nonReentrant {
        if (callback == address(0)) revert AddressZero();
        _stage(_depositCallback, bytes32(bytes20(callback)));
    }

    function commitDepositCallback() external onlyAdmin nonReentrant {
        _commit(_depositCallback, _depositCallbackDelay);
    }

    function rollbackStagedDepositCallback() external onlyAdmin nonReentrant {
        _rollback(_depositCallback);
    }

    function stageWithdrawalCallback(
        address callback
    ) external onlyAdmin nonReentrant {
        if (callback == address(0)) revert AddressZero();
        _stage(_withdrawalCallback, bytes32(bytes20(callback)));
    }

    function commitWithdrawalCallback() external onlyAdmin nonReentrant {
        _commit(_withdrawalCallback, _withdrawalCallbackDelay);
    }

    function rollbackStagedWithdrawalCallback()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_withdrawalCallback);
    }

    function stageWithdrawalFeeD9(
        uint256 feeD9
    ) external onlyAdmin nonReentrant {
        if (feeD9 > MAX_WITHDRAWAL_FEE) revert InvalidWithdrawalFee();
        _stage(_withdrawalFeeD9, bytes32(feeD9));
    }

    function commitWithdrawalFeeD9() external onlyAdmin nonReentrant {
        _commit(_withdrawalFeeD9, _withdrawalFeeD9Delay);
    }

    function rollbackStagedWithdrawalFeeD9() external onlyAdmin nonReentrant {
        _rollback(_withdrawalFeeD9);
    }

    function baseDelay() public view returns (uint256) {
        return uint256(_baseDelay.value);
    }

    function stageBaseDelay(uint256 delay_) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_baseDelay, bytes32(delay_));
    }

    function commitBaseDelay() external onlyAdmin nonReentrant {
        _commit(_baseDelay, _baseDelay);
    }

    function rollbackStagedBaseDelay() external onlyAdmin nonReentrant {
        _rollback(_baseDelay);
    }

    function deployCallbackDelay() public view returns (uint256) {
        return uint256(_depositCallbackDelay.value);
    }

    function stageDeployCallbackDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_depositCallbackDelay, bytes32(delay_));
    }

    function commitDeployCallbackDelay() external onlyAdmin nonReentrant {
        _commit(_depositCallbackDelay, _baseDelay);
    }

    function rollbackStagedDeployCallbackDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_depositCallbackDelay);
    }

    function withdrawalCallbackDelay() public view returns (uint256) {
        return uint256(_withdrawalCallbackDelay.value);
    }

    function stageWithdrawalCallbackDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_withdrawalCallbackDelay, bytes32(delay_));
    }

    function commitWithdrawalCallbackDelay() external onlyAdmin nonReentrant {
        _commit(_withdrawalCallbackDelay, _baseDelay);
    }

    function rollbackStagedWithdrawalCallbackDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_withdrawalCallbackDelay);
    }

    function withdrawFeeD9Delay() public view returns (uint256) {
        return uint256(_withdrawalFeeD9Delay.value);
    }

    function stageWithdrawFeeD9Delay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_withdrawalFeeD9Delay, bytes32(delay_));
    }

    function commitWithdrawFeeD9Delay() external onlyAdmin nonReentrant {
        _commit(_withdrawalFeeD9Delay, _baseDelay);
    }

    function rollbackStagedWithdrawFeeD9Delay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_withdrawalFeeD9Delay);
    }

    function isDepositsLockedDelay() public view returns (uint256) {
        return uint256(_isDepositsLockedDelay.value);
    }

    function stageDepositsLockedDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_isDepositsLockedDelay, bytes32(delay_));
    }

    function commitDepositsLockedDelay() external onlyAdmin nonReentrant {
        _commit(_isDepositsLockedDelay, _baseDelay);
    }

    function rollbackStagedDepositsLockedDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_isDepositsLockedDelay);
    }

    function delegateModuleApprovalDelay() public view returns (uint256) {
        return uint256(_isDelegateModuleApprovedDelay.value);
    }

    function stageDelegateModuleApprovalDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_isDelegateModuleApprovedDelay, bytes32(delay_));
    }

    function commitDelegateModuleApprovalDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _commit(_isDelegateModuleApprovedDelay, _baseDelay);
    }

    function rollbackStagedDelegateModuleApprovalDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_isDelegateModuleApprovedDelay);
    }

    function maximalTotalSupplyDelay() public view returns (uint256) {
        return uint256(_maximalTotalSupplyDelay.value);
    }

    function stageMaximalTotalSupplyDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_maximalTotalSupplyDelay, bytes32(delay_));
    }

    function commitMaximalTotalSupplyDelay() external onlyAdmin nonReentrant {
        _commit(_maximalTotalSupplyDelay, _baseDelay);
    }

    function rollbackStagedMaximalTotalSupplyDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_maximalTotalSupplyDelay);
    }

    function ratiosOracle() external view returns (address) {
        return address(bytes20(_ratiosOracle.value));
    }

    function priceOracle() external view returns (address) {
        return address(bytes20(_priceOracle.value));
    }

    function validator() external view returns (address) {
        return address(bytes20(_validator.value));
    }

    function stageRatiosOracle(address oracle) external onlyAdmin nonReentrant {
        if (oracle == address(0)) revert AddressZero();
        _stage(_ratiosOracle, bytes32(bytes20(oracle)));
    }

    function commitRatiosOracle() external onlyAdmin nonReentrant {
        _commit(_ratiosOracle, _ratiosOracleDelay);
    }

    function rollbackStagedRatiosOracle() external onlyAdmin nonReentrant {
        _rollback(_ratiosOracle);
    }

    function stagePriceOracle(address oracle) external onlyAdmin nonReentrant {
        if (oracle == address(0)) revert AddressZero();
        _stage(_priceOracle, bytes32(bytes20(oracle)));
    }

    function commitPriceOracle() external onlyAdmin nonReentrant {
        _commit(_priceOracle, _priceOracleDelay);
    }

    function rollbackStagedPriceOracle() external onlyAdmin nonReentrant {
        _rollback(_priceOracle);
    }

    function stageValidator(
        address validator_
    ) external onlyAdmin nonReentrant {
        if (validator_ == address(0)) revert AddressZero();
        _stage(_validator, bytes32(bytes20(validator_)));
    }

    function commitValidator() external onlyAdmin nonReentrant {
        _commit(_validator, _validatorDelay);
    }

    function rollbackStagedValidator() external onlyAdmin nonReentrant {
        _rollback(_validator);
    }

    function validatorDelay() public view returns (uint256) {
        return uint256(_validatorDelay.value);
    }

    function stageValidatorDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_validatorDelay, bytes32(delay_));
    }

    function commitValidatorDelay() external onlyAdmin nonReentrant {
        _commit(_validatorDelay, _baseDelay);
    }

    function rollbackStagedValidatorDelay() external onlyAdmin nonReentrant {
        _rollback(_validatorDelay);
    }

    function stagePriceOracleDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_priceOracleDelay, bytes32(delay_));
    }

    function commitPriceOracleDelay() external onlyAdmin nonReentrant {
        _commit(_priceOracleDelay, _baseDelay);
    }

    function rollbackStagedPriceOracleDelay() external onlyAdmin nonReentrant {
        _rollback(_priceOracleDelay);
    }

    function stageRatiosOracleDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_ratiosOracleDelay, bytes32(delay_));
    }

    function commitRatiosOracleDelay() external onlyAdmin nonReentrant {
        _commit(_ratiosOracleDelay, _baseDelay);
    }

    function rollbackStagedRatiosOracleDelay() external onlyAdmin nonReentrant {
        _rollback(_ratiosOracleDelay);
    }

    function emergencyWithdrawalDelay() public view returns (uint256) {
        return uint256(_emergencyWithdrawalDelay.value);
    }

    function stageEmergencyWithdrawalDelay(
        uint256 delay_
    ) external onlyAdmin nonReentrant {
        if (delay_ > MAX_DELAY) revert InvalidDelay();
        _stage(_emergencyWithdrawalDelay, bytes32(delay_));
    }

    function commitEmergencyWithdrawalDelay() external onlyAdmin nonReentrant {
        _commit(_emergencyWithdrawalDelay, _baseDelay);
    }

    function rollbackStagedEmergencyWithdrawalDelay()
        external
        onlyAdmin
        nonReentrant
    {
        _rollback(_emergencyWithdrawalDelay);
    }
}
