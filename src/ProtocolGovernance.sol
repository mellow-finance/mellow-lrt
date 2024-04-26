// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./utils/DefaultAccessControl.sol";

contract ProtocolGovernance is ReentrancyGuard, DefaultAccessControl {
    uint256 public constant MAX_GOVERNANCE_DELAY = 30 days;
    uint256 public constant MAX_WITHDRAWAL_FEE = 5e7; // 5%

    uint256 public governanceDelay;
    uint256 public governanceDelayStageTimestamp;
    uint256 public stagedGovernanceDelay;

    mapping(address => uint256) public delegateModulesStageTimestamps;
    mapping(address => bool) public approvedDelegateModules;

    mapping(address => uint256) public stagedMaxTotalSupply;
    mapping(address => uint256) public stagedMaxTotalSupplyTimestamp;
    mapping(address => uint256) public maxTotalSupply;

    mapping(address => address) public stagedDepositCallback;
    mapping(address => uint256) public stagedDepositCallbackTimestamp;
    mapping(address => address) public depositCallback;

    mapping(address => address) public stagedWithdrawalCallback;
    mapping(address => uint256) public stagedWithdrawalCallbackTimestamp;
    mapping(address => address) public withdrawalCallback;

    mapping(address => uint256) public stagedWithdrawalFeeD9;
    mapping(address => uint256) public stagedWithdrawalFeeD9Timestamp;
    mapping(address => uint256) public withdrawalFeeD9;

    modifier onlyAdmin() {
        if (!isAdmin(msg.sender))
            revert("ProtocolGovernance: caller is not the admin");
        _;
    }
    constructor(
        address admin,
        uint256 governanceDelay_
    ) DefaultAccessControl(admin) {
        if (governanceDelay_ == 0 || governanceDelay_ > MAX_GOVERNANCE_DELAY)
            revert("ProtocolGovernance: invalid governance delay");
        governanceDelay = governanceDelay_;
    }

    function _validateTimestamp(uint256 timestamp) internal view {
        if (timestamp == 0) revert("ProtocolGovernance: timestamp is not set");
        if (block.timestamp - timestamp < governanceDelay)
            revert("ProtocolGovernance: stage delay has not passed");
    }

    function stageDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        delegateModulesStageTimestamps[module] = block.timestamp;
    }

    function commitDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        _validateTimestamp(delegateModulesStageTimestamps[module]);
        approvedDelegateModules[module] = true;
        delete delegateModulesStageTimestamps[module];
    }

    function rollbackStagedDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        delete delegateModulesStageTimestamps[module];
    }

    function revokeDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        delete approvedDelegateModules[module];
    }

    function stageMaximalTotalSupply(
        address vault,
        uint256 totalSupply
    ) external onlyAdmin nonReentrant {
        stagedMaxTotalSupplyTimestamp[vault] = block.timestamp;
        stagedMaxTotalSupply[vault] = totalSupply;
    }

    function commitMaximalTotalSupply(
        address vault
    ) external onlyAdmin nonReentrant {
        _validateTimestamp(stagedMaxTotalSupplyTimestamp[vault]);
        maxTotalSupply[vault] = stagedMaxTotalSupply[vault];
        delete stagedMaxTotalSupplyTimestamp[vault];
        delete stagedMaxTotalSupply[vault];
    }

    function rollbackStagedMaximalTotalSupply(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedMaxTotalSupplyTimestamp[vault];
        delete stagedMaxTotalSupply[vault];
    }

    function stageDepositCallback(
        address vault,
        address callback
    ) external onlyAdmin nonReentrant {
        stagedDepositCallbackTimestamp[vault] = block.timestamp;
        stagedDepositCallback[vault] = callback;
    }

    function commitDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _validateTimestamp(stagedDepositCallbackTimestamp[vault]);
        depositCallback[vault] = stagedDepositCallback[vault];
        delete stagedDepositCallbackTimestamp[vault];
        delete stagedDepositCallback[vault];
    }

    function rollbackStagedDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedDepositCallbackTimestamp[vault];
        delete stagedDepositCallback[vault];
    }

    function revokeDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        delete depositCallback[vault];
    }

    function stageWithdrawalCallback(
        address vault,
        address callback
    ) external onlyAdmin nonReentrant {
        stagedWithdrawalCallbackTimestamp[vault] = block.timestamp;
        stagedWithdrawalCallback[vault] = callback;
    }

    function commitWithdrawalCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        _validateTimestamp(stagedWithdrawalCallbackTimestamp[vault]);
        withdrawalCallback[vault] = stagedWithdrawalCallback[vault];
        delete stagedWithdrawalCallbackTimestamp[vault];
        delete stagedWithdrawalCallback[vault];
    }

    function rollbackStagedWithdrawalCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedWithdrawalCallbackTimestamp[vault];
        delete stagedWithdrawalCallback[vault];
    }

    function revokeWithdrawlCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        delete withdrawalCallback[vault];
    }

    function stageGovernanceDelay(
        uint256 delay
    ) external onlyAdmin nonReentrant {
        if (delay == 0 || delay > MAX_GOVERNANCE_DELAY)
            revert("ProtocolGovernance: invalid governance delay");
        governanceDelayStageTimestamp = block.timestamp;
        stagedGovernanceDelay = delay;
    }

    function commitGovernanceDelay() external onlyAdmin nonReentrant {
        _validateTimestamp(governanceDelayStageTimestamp);
        governanceDelay = stagedGovernanceDelay;
        delete governanceDelayStageTimestamp;
        delete stagedGovernanceDelay;
    }

    function rollbackStagedGovernanceDelay() external onlyAdmin nonReentrant {
        delete governanceDelayStageTimestamp;
        delete stagedGovernanceDelay;
    }

    function stageWithdrawalFeeD9(
        address vault,
        uint256 feeD9
    ) external onlyAdmin nonReentrant {
        if (feeD9 > MAX_WITHDRAWAL_FEE)
            revert("ProtocolGovernance: withdrawal fee is too high");
        stagedWithdrawalFeeD9Timestamp[vault] = block.timestamp;
        stagedWithdrawalFeeD9[vault] = feeD9;
    }

    function commitWithdrawalFeeD9(
        address vault
    ) external onlyAdmin nonReentrant {
        _validateTimestamp(stagedWithdrawalFeeD9Timestamp[vault]);
        withdrawalFeeD9[vault] = stagedWithdrawalFeeD9[vault];
        delete stagedWithdrawalFeeD9Timestamp[vault];
        delete stagedWithdrawalFeeD9[vault];
    }

    function rollbackStagedWithdrawalFeeD9(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedWithdrawalFeeD9Timestamp[vault];
        delete stagedWithdrawalFeeD9[vault];
    }
}
