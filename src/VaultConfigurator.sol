// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IVaultConfigurator.sol";

import "./utils/DefaultAccessControl.sol";

contract VaultConfigurator is
    IVaultConfigurator,
    ReentrancyGuard,
    DefaultAccessControl
{
    uint256 public constant MAX_GOVERNANCE_DELAY = 30 days;
    uint256 public constant MAX_WITHDRAWAL_FEE = 5e7; // 5%

    // add custom delays for parameters
    Data private _governanceDelay;
    mapping(address => Data) private _isDelegateModuleApproved;
    mapping(address => Data) private _isExternalCallsApproved;
    mapping(address => Data) private _maxTotalSupply;
    mapping(address => Data) private _depositCallback;
    mapping(address => Data) private _withdrawalCallback;
    mapping(address => Data) private _withdrawalFeeD9;

    function isDelegateModuleApproved(
        address target
    ) external view returns (bool) {
        return _isDelegateModuleApproved[target].value != bytes32(0);
    }

    function isExternalCallsApproved(
        address target
    ) external view returns (bool) {
        return _isExternalCallsApproved[target].value != bytes32(0);
    }

    function maximalTotalSupply(address vault) external view returns (uint256) {
        return uint256(_maxTotalSupply[vault].value);
    }

    function depositCallback(address vault) external view returns (address) {
        return address(bytes20(_depositCallback[vault].value));
    }

    function withdrawalCallback(address vault) external view returns (address) {
        return address(bytes20(_withdrawalCallback[vault].value));
    }

    function withdrawalFeeD9(address vault) external view returns (uint256) {
        return uint256(_withdrawalFeeD9[vault].value);
    }

    function maximalTotalSupplyStagedValue(
        address vault
    ) external view returns (uint256) {
        return uint256(_maxTotalSupply[vault].stagedValue);
    }

    function depositCallbackStagedValue(
        address vault
    ) external view returns (address) {
        return address(bytes20(_depositCallback[vault].stagedValue));
    }

    function withdrawalCallbackStagedValue(
        address vault
    ) external view returns (address) {
        return address(bytes20(_withdrawalCallback[vault].stagedValue));
    }

    function withdrawalFeeD9StagedValue(
        address vault
    ) external view returns (uint256) {
        return uint256(_withdrawalFeeD9[vault].stagedValue);
    }

    function isDelegateModuleApprovedStagedTimestamp(
        address target
    ) external view returns (uint256) {
        return _isDelegateModuleApproved[target].stageTimestamp;
    }

    function isExternalCallsApprovedStagedTimestamp(
        address target
    ) external view returns (uint256) {
        return _isExternalCallsApproved[target].stageTimestamp;
    }

    function maximalTotalSupplyStagedTimestamp(
        address vault
    ) external view returns (uint256) {
        return _maxTotalSupply[vault].stageTimestamp;
    }

    function depositCallbackStagedTimestamp(
        address vault
    ) external view returns (uint256) {
        return _depositCallback[vault].stageTimestamp;
    }

    function withdrawalCallbackStagedTimestamp(
        address vault
    ) external view returns (uint256) {
        return _withdrawalCallback[vault].stageTimestamp;
    }

    function withdrawalFeeD9StagedTimestamp(
        address vault
    ) external view returns (uint256) {
        return _withdrawalFeeD9[vault].stageTimestamp;
    }

    function governanceDelay() external view override returns (uint256) {
        return uint256(_governanceDelay.value);
    }

    function governanceDelayStageTimestamp()
        external
        view
        override
        returns (uint256)
    {
        return _governanceDelay.stageTimestamp;
    }

    function stagedGovernanceDelay() external view override returns (uint256) {
        return uint256(_governanceDelay.stagedValue);
    }

    modifier onlyAdmin() {
        if (!isAdmin(msg.sender))
            revert("ProtocolGovernance: caller is not the admin");
        _;
    }

    constructor(address admin) DefaultAccessControl(admin) {}

    function _validateTimestamp(uint256 timestamp) private view {
        if (timestamp == 0) revert("ProtocolGovernance: timestamp is not set");
        if (block.timestamp - timestamp < uint256(_governanceDelay.value))
            revert("ProtocolGovernance: stage delay has not passed");
    }

    function _stage(Data storage s, bytes32 value) private {
        s.stageTimestamp = block.timestamp;
        s.stagedValue = value;
    }

    function _commit(Data storage s) private {
        _validateTimestamp(s.stageTimestamp);
        s.value = s.stagedValue;
        delete s.stageTimestamp;
        delete s.stagedValue;
    }

    function _rollback(Data storage s) private {
        delete s.stageTimestamp;
        delete s.stagedValue;
    }

    function _revoke(Data storage s) private {
        delete s.value;
    }

    function stageDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        if (module == address(0)) revert("ProtocolGovernance: address zero");
        _stage(_isDelegateModuleApproved[module], bytes32(uint256(1)));
    }

    function commitDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _commit(_isDelegateModuleApproved[module]);
    }

    function rollbackStagedDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _rollback(_isDelegateModuleApproved[module]);
    }

    function revokeDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _revoke(_isDelegateModuleApproved[module]);
    }

    function stageExternalCallsApproval(
        address target
    ) external onlyAdmin nonReentrant {
        if (target == address(0)) revert("ProtocolGovernance: address zero");
        _stage(_isExternalCallsApproved[target], bytes32(uint256(1)));
    }

    function commitExternalCallsApproval(
        address target
    ) external onlyAdmin nonReentrant {
        _commit(_isExternalCallsApproved[target]);
    }

    function rollbackStagedExternalCallsApproval(
        address target
    ) external onlyAdmin nonReentrant {
        _rollback(_isExternalCallsApproved[target]);
    }

    function revokeExternalCallsApproval(
        address target
    ) external onlyAdmin nonReentrant {
        _revoke(_isExternalCallsApproved[target]);
    }

    function stageMaximalTotalSupply(
        address vault,
        uint256 maximalTotalSupply_
    ) external onlyAdmin nonReentrant {
        if (vault == address(0)) revert("ProtocolGovernance: address zero");
        _stage(_maxTotalSupply[vault], bytes32(maximalTotalSupply_));
    }

    function commitMaximalTotalSupply(
        address vault
    ) external onlyAdmin nonReentrant {
        _commit(_maxTotalSupply[vault]);
    }

    function rollbackStagedMaximalTotalSupply(
        address vault
    ) external onlyAdmin nonReentrant {
        _rollback(_maxTotalSupply[vault]);
    }

    function stageDepositCallback(
        address vault,
        address callback
    ) external onlyAdmin nonReentrant {
        if (callback == address(0) || vault == address(0))
            revert("ProtocolGovernance: address zero");
        _stage(_depositCallback[vault], bytes32(bytes20(callback)));
    }

    function commitDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _commit(_depositCallback[vault]);
    }

    function rollbackStagedDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _rollback(_depositCallback[vault]);
    }

    function revokeDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _revoke(_depositCallback[vault]);
    }

    function stageWithdrawalCallback(
        address vault,
        address callback
    ) external onlyAdmin nonReentrant {
        if (callback == address(0) || vault == address(0))
            revert("ProtocolGovernance: address zero");
        _stage(_withdrawalCallback[vault], bytes32(bytes20(callback)));
    }

    function commitWithdrawalCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _commit(_withdrawalCallback[vault]);
    }

    function rollbackStagedWithdrawalCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _rollback(_withdrawalCallback[vault]);
    }

    function revokeWithdrawlCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _revoke(_withdrawalCallback[vault]);
    }

    function stageGovernanceDelay(
        uint256 delay
    ) external onlyAdmin nonReentrant {
        if (delay == 0 || delay > MAX_GOVERNANCE_DELAY)
            revert("ProtocolGovernance: invalid governance delay");
        _stage(_governanceDelay, bytes32(delay));
    }

    function commitGovernanceDelay() external onlyAdmin nonReentrant {
        _commit(_governanceDelay);
    }

    function rollbackStagedGovernanceDelay() external onlyAdmin nonReentrant {
        _rollback(_governanceDelay);
    }

    function stageWithdrawalFeeD9(
        address vault,
        uint256 feeD9
    ) external onlyAdmin nonReentrant {
        if (vault == address(0)) revert("ProtocolGovernance: invalid vault");
        if (feeD9 > MAX_WITHDRAWAL_FEE)
            revert("ProtocolGovernance: fee is too high");
        _stage(_withdrawalFeeD9[vault], bytes32(feeD9));
    }

    function commitWithdrawalFeeD9(
        address vault
    ) external onlyAdmin nonReentrant {
        _commit(_withdrawalFeeD9[vault]);
    }

    function rollbackStagedWithdrawalFeeD9(
        address vault
    ) external onlyAdmin nonReentrant {
        _rollback(_withdrawalFeeD9[vault]);
    }
}
