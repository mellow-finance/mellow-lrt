// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IProtocolGovernance {
    function MAX_GOVERNANCE_DELAY() external view returns (uint256);
    function MAX_WITHDRAWAL_FEE() external view returns (uint256);

    function governanceDelay() external view returns (uint256);
    function governanceDelayStageTimestamp() external view returns (uint256);
    function stagedGovernanceDelay() external view returns (uint256);

    function delegateModulesStageTimestamps(
        address
    ) external view returns (uint256);
    function approvedDelegateModules(address) external view returns (bool);

    function stagedMaxTotalSupply(address) external view returns (uint256);
    function stagedMaxTotalSupplyTimestamp(
        address
    ) external view returns (uint256);
    function maxTotalSupply(address) external view returns (uint256);

    function stagedDepositCallback(address) external view returns (address);
    function stagedDepositCallbackTimestamp(
        address
    ) external view returns (uint256);
    function depositCallback(address) external view returns (address);

    function stagedWithdrawalCallback(address) external view returns (address);
    function stagedWithdrawalCallbackTimestamp(
        address
    ) external view returns (uint256);
    function withdrawalCallback(address) external view returns (address);

    function stagedWithdrawalFeeD9(address) external view returns (uint256);
    function stagedWithdrawalFeeD9Timestamp(
        address
    ) external view returns (uint256);
    function withdrawalFeeD9(address) external view returns (uint256);

    function stageDelegateModuleApproval(address module) external;
    function commitDelegateModuleApproval(address module) external;

    function rollbackStagedDelegateModuleApproval(address module) external;
    function revokeDelegateModuleApproval(address module) external;
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
