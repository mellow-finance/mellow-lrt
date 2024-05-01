// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVaultConfigurator {
    struct Data {
        bytes32 value;
        bytes32 stagedValue;
        uint256 stageTimestamp;
    }

    function MAX_GOVERNANCE_DELAY() external view returns (uint256);

    function MAX_WITHDRAWAL_FEE() external view returns (uint256);

    function governanceDelay() external view returns (uint256);

    function governanceDelayStageTimestamp() external view returns (uint256);

    function stagedGovernanceDelay() external view returns (uint256);

    function isDelegateModuleApproved(
        address target
    ) external view returns (bool);

    function isExternalCallsApproved(
        address target
    ) external view returns (bool);

    function maximalTotalSupply(address vault) external view returns (uint256);

    function depositCallback(address vault) external view returns (address);

    function withdrawalCallback(address vault) external view returns (address);

    function withdrawalFeeD9(address vault) external view returns (uint256);

    function maximalTotalSupplyStagedValue(
        address vault
    ) external view returns (uint256);

    function depositCallbackStagedValue(
        address vault
    ) external view returns (address);

    function withdrawalCallbackStagedValue(
        address vault
    ) external view returns (address);

    function withdrawalFeeD9StagedValue(
        address vault
    ) external view returns (uint256);

    function isDelegateModuleApprovedStagedTimestamp(
        address target
    ) external view returns (uint256);

    function isExternalCallsApprovedStagedTimestamp(
        address target
    ) external view returns (uint256);

    function maximalTotalSupplyStagedTimestamp(
        address vault
    ) external view returns (uint256);

    function depositCallbackStagedTimestamp(
        address vault
    ) external view returns (uint256);

    function withdrawalCallbackStagedTimestamp(
        address vault
    ) external view returns (uint256);

    function withdrawalFeeD9StagedTimestamp(
        address vault
    ) external view returns (uint256);

    function stageDelegateModuleApproval(address module) external;

    function commitDelegateModuleApproval(address module) external;

    function rollbackStagedDelegateModuleApproval(address module) external;

    function revokeDelegateModuleApproval(address module) external;

    function stageExternalCallsApproval(address target) external;

    function commitExternalCallsApproval(address target) external;

    function rollbackStagedExternalCallsApproval(address target) external;

    function revokeExternalCallsApproval(address target) external;

    function stageMaximalTotalSupply(
        address vault,
        uint256 totalSupply
    ) external;

    function commitMaximalTotalSupply(address vault) external;

    function rollbackStagedMaximalTotalSupply(address vault) external;

    function stageDepositCallback(address vault, address callback) external;

    function commitDepositCallback(address vault) external;

    function rollbackStagedDepositCallback(address vault) external;

    function revokeDepositCallback(address vault) external;

    function stageWithdrawalCallback(address vault, address callback) external;

    function commitWithdrawalCallback(address vault) external;

    function rollbackStagedWithdrawalCallback(address vault) external;

    function revokeWithdrawlCallback(address vault) external;

    function stageGovernanceDelay(uint256 delay) external;

    function commitGovernanceDelay() external;

    function rollbackStagedGovernanceDelay() external;

    function stageWithdrawalFeeD9(address vault, uint256 feeD9) external;

    function commitWithdrawalFeeD9(address vault) external;

    function rollbackStagedWithdrawalFeeD9(address vault) external;
}
