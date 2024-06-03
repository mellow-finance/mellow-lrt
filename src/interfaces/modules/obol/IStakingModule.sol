// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../external/lido/IWeth.sol";
import "../../external/lido/ISteth.sol";
import "../../external/lido/IWSteth.sol";
import "../../external/lido/IWithdrawalQueue.sol";
import "../../external/lido/IDepositSecurityModule.sol";
import "../../external/lido/IStakingRouter.sol";

/**
 * @title IStakingModule
 * @notice Staking module handles the secure conversion and deposit of assets into staking mechanisms.
 *
 * @dev Implements functions to convert and safely deposit assets into the Lido staking modules while adhering
 * to security checks and balances provided by a committee of guardians within the Deposit Security Module.
 */
interface IStakingModule {
    /// @dev Custom errors:
    error NotEnoughWeth();
    error InvalidWithdrawalQueueState();
    error InvalidAmount();

    /**
     * @return Address of the WETH token.
     */
    function weth() external view returns (address);

    /**
     * @return Address of the stETH token.
     */
    function steth() external view returns (address);

    /**
     * @return Address of the wstETH token.
     */
    function wsteth() external view returns (address);

    /**
     * @notice Interface to the Deposit Security Module of Lido.
     * @return IDepositSecurityModule The deposit security module address.
     */
    function depositSecurityModule()
        external
        view
        returns (IDepositSecurityModule);

    /**
     * @notice Interface to the Withdrawal Queue module.
     * @return The withdrawal queue address.
     */
    function withdrawalQueue() external view returns (IWithdrawalQueue);

    /**
     * @notice The unique identifier for this staking module.
     * @return An immutable identifier used to differentiate this module within a system of multiple modules.
     */
    function stakingModuleId() external view returns (uint256);

    /**
     * @notice Converts a specified amount of wETH directly to wstETH, ensuring all security protocols are adhered to.
     * @param amount The amount of wETH to convert.
     */
    function convert(uint256 amount) external;

    /**
     * @notice Converts wETH to wstETH and securely deposits it into the staking contract according to the specified security protocols.
     * @param blockNumber The block number at the time of the deposit operation, used for security verification.
     * @param blockHash The hash of the block at the time of the deposit, used for security verification.
     * @param depositRoot The merkle root of the deposit records, used for security verification.
     * @param nonce A nonce to ensure uniqueness of the deposit operation.
     * @param depositCalldata Additional calldata required for the deposit operation.
     * @param sortedGuardianSignatures Signatures from guardians to authenticate and secure the deposit.
     * Signatures must be sorted in ascending order by address of the guardian. Each signature must
     * be produced for the keccak256 hash of the following message (each component taking 32 bytes):
     *
     * | ATTEST_MESSAGE_PREFIX | blockNumber | blockHash | depositRoot | stakingModuleId | nonce |
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
     * @notice Emitted when wETH is converted to wstETH.
     * @param amount The amount of wETH that was converted.
     */
    event Converted(uint256 amount);

    /**
     * @notice Emitted after the assets are securely deposited.
     * @param amount The amount of assets that were deposited.
     * @param blockNumber The block number at which the deposit was recorded.
     */
    event DepositCompleted(uint256 amount, uint256 blockNumber);
}
