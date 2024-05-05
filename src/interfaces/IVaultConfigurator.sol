// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IVaultConfigurator {
    error InvalidTimestamp();
    error InvalidWithdrawalFee();
    error InvalidDelay();
    error InvalidSlot();

    struct Data {
        uint256 value;
        uint256 stagedValue;
        uint256 stageTimestamp;
    }

    function emergencyWithdrawalDelay() external view returns (uint256);

    function ratiosOracle() external view returns (address);

    function priceOracle() external view returns (address);

    function validator() external view returns (address);

    function isDelegateModuleApproved(
        address target
    ) external view returns (bool);

    function isDepositsLocked() external view returns (bool);

    function maximalTotalSupply() external view returns (uint256);

    function depositCallback() external view returns (address);

    function withdrawalCallback() external view returns (address);

    function withdrawalFeeD9() external view returns (uint256);

    function stageDelegateModuleApproval(address module) external;

    function commitDelegateModuleApproval(address module) external;

    function rollbackStagedDelegateModuleApproval(address module) external;

    function revokeDelegateModuleApproval(address module) external;

    function stageMaximalTotalSupply(uint256 maximalTotalSupply_) external;

    function commitMaximalTotalSupply() external;

    function rollbackStagedMaximalTotalSupply() external;

    function stageDepositCallback(address callback) external;

    function commitDepositCallback() external;

    function rollbackStagedDepositCallback() external;

    function stageWithdrawalCallback(address callback) external;

    function commitWithdrawalCallback() external;

    function rollbackStagedWithdrawalCallback() external;

    function stageWithdrawalFeeD9(uint256 feeD9) external;

    function commitWithdrawalFeeD9() external;

    function rollbackStagedWithdrawalFeeD9() external;
}
