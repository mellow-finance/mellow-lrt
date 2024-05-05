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

    function MAX_DELAY() external view returns (uint256);
    function MAX_WITHDRAWAL_FEE() external view returns (uint256);

    function isDelegateModuleApproved(
        address module
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

    function stageDepositsLock() external;
    function commitDepositsLock() external;

    function rollbackStagedDepositsLock() external;

    function revokeDepositsLock() external;

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
    function baseDelay() external view returns (uint256);
    function stageBaseDelay(uint256 delay_) external;

    function commitBaseDelay() external;

    function rollbackStagedBaseDelay() external;

    function depositCallbackDelay() external view returns (uint256);
    function stageDepositCallbackDelay(uint256 delay_) external;

    function commitDepositCallbackDelay() external;
    function rollbackStagedDepositCallbackDelay() external;
    function withdrawalCallbackDelay() external view returns (uint256);

    function stageWithdrawalCallbackDelay(uint256 delay_) external;

    function commitWithdrawalCallbackDelay() external;

    function rollbackStagedWithdrawalCallbackDelay() external;

    function withdrawalFeeD9Delay() external view returns (uint256);
    function stageWithdrawalFeeD9Delay(uint256 delay_) external;

    function commitWithdrawalFeeD9Delay() external;

    function rollbackStagedWithdrawalFeeD9Delay() external;

    function isDepositsLockedDelay() external view returns (uint256);
    function stageDepositsLockedDelay(uint256 delay_) external;

    function commitDepositsLockedDelay() external;
    function rollbackStagedDepositsLockedDelay() external;
    function delegateModuleApprovalDelay() external view returns (uint256);
    function stageDelegateModuleApprovalDelay(uint256 delay_) external;
    function commitDelegateModuleApprovalDelay() external;
    function rollbackStagedDelegateModuleApprovalDelay() external;
    function maximalTotalSupplyDelay() external view returns (uint256);

    function stageMaximalTotalSupplyDelay(uint256 delay_) external;

    function commitMaximalTotalSupplyDelay() external;

    function rollbackStagedMaximalTotalSupplyDelay() external;

    function ratiosOracle() external view returns (address);
    function priceOracle() external view returns (address);
    function validator() external view returns (address);
    function stageRatiosOracle(address oracle) external;

    function commitRatiosOracle() external;
    function rollbackStagedRatiosOracle() external;

    function stagePriceOracle(address oracle) external;

    function commitPriceOracle() external;

    function rollbackStagedPriceOracle() external;
    function stageValidator(address validator_) external;

    function commitValidator() external;

    function rollbackStagedValidator() external;
    function priceOracleDelay() external view returns (uint256);

    function ratiosOracleDelay() external view returns (uint256);
    function validatorDelay() external view returns (uint256);
    function stageValidatorDelay(uint256 delay_) external;
    function commitValidatorDelay() external;

    function rollbackStagedValidatorDelay() external;

    function stagePriceOracleDelay(uint256 delay_) external;

    function commitPriceOracleDelay() external;
    function rollbackStagedPriceOracleDelay() external;
    function stageRatiosOracleDelay(uint256 delay_) external;

    function commitRatiosOracleDelay() external;

    function rollbackStagedRatiosOracleDelay() external;

    function emergencyWithdrawalDelay() external view returns (uint256);

    function stageEmergencyWithdrawalDelay(uint256 delay_) external;

    function commitEmergencyWithdrawalDelay() external;

    function rollbackStagedEmergencyWithdrawalDelay() external;
}
