// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../modules/obol/IStakingModule.sol";
import "../IVault.sol";

/**
 * @title ISimpleDVTStakingStrategy
 * @dev The strategy uses the staking module for converting tokens and the vault for managing the deposits and withdrawals.
 */
interface ISimpleDVTStakingStrategy {
    /// @dev Custom errors:
    error NotEnoughWeth(); // Thrown if the contract has insufficient WETH for operations.
    error InvalidWithdrawalQueueState(); // Thrown if the withdrawal queue state is inconsistent or invalid.
    error LimitOverflow(); // Thrown if the maximum allowed remainder is exceeded.
    error DepositFailed(); // Thrown if the deposit operation failed.

    /**
     * @return The vault address.
     */
    function vault() external view returns (IVault);

    /**
     * @return The staking module address.
     */
    function stakingModule() external view returns (IStakingModule);

    /**
     * @notice Returns the maximum allowed remainder of staked tokens in the vault after the convert operation.
     * @return The maximum allowed remainder.
     */
    function maxAllowedRemainder() external view returns (uint256);

    /**
     * @notice Sets the maximum allowed remainder of staked tokens in the vault.
     * @param newMaxAllowedRemainder The new maximum remainder allowed.
     */
    function setMaxAllowedRemainder(uint256 newMaxAllowedRemainder) external;

    /**
     * @notice Converts and deposits into specific staking module.
     * @param blockNumber The block number at the time of the operation for verification.
     * @param blockHash The block hash at the time of the operation for additional verification.
     * @param depositRoot The root hash of the deposit records for verification.
     * @param nonce A nonce to ensure the uniqueness of the operation.
     * @param depositCalldata The calldata required for the deposit operation.
     * @param sortedGuardianSignatures The signatures from guardians verifying the operation.
     * @notice The function can be called by anyone.
     */
    function convertAndDeposit(
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 nonce,
        bytes calldata depositCalldata,
        IDepositSecurityModule.Signature[] calldata sortedGuardianSignatures
    ) external;

    /**
     * @notice Processes withdrawals from the vault, possibly staking some of the withdrawn assets.
     * @param users An array of user addresses to process withdrawals for.
     * @param amountForStake The amount from the withdrawals to be staked.
     * @return statuses An array of booleans indicating the success of each individual withdrawal.
     */
    function processWithdrawals(
        address[] memory users,
        uint256 amountForStake
    ) external returns (bool[] memory statuses);

    /**
     * @notice Emitted when the max allowed remainder is updated.
     * @param newMaxAllowedRemainder The new maximum allowed remainder.
     * @param sender The address of the admin who made the change.
     */
    event MaxAllowedRemainderChanged(
        uint256 newMaxAllowedRemainder,
        address sender
    );

    /**
     * @notice Emitted after attempting to convert and deposit tokens via the staking module.
     * @param sender The address that initiated the operation.
     */
    event ConvertAndDeposit(address sender);

    /**
     * @notice Emitted when processing withdrawals.
     * @param users Array of user addresses involved in the withdrawal process.
     * @param amountForStake The amount of assets intended forstaking.
     * @param sender The address that initiated the withdrawal process.
     */
    event ProcessWithdrawals(
        address[] users,
        uint256 amountForStake,
        address sender
    );
}
