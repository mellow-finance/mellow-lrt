// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../external/symbiotic/IDefaultBond.sol";

// Interface declaration for Default Bond Module
interface IDefaultBondModule {
    /**
     * @notice Deposits a specified amount of tokens into a bond contract.
     * @param bond Address of the bond contract.
     * @param amount Amount of tokens to deposit.
     * @return The amount of tokens deposited.
     */
    function deposit(address bond, uint256 amount) external returns (uint256);

    /**
     * @notice Withdraws a specified amount of tokens from a bond contract.
     * @param bond Address of the bond contract.
     * @param amount Amount of tokens to withdraw.
     * @return The amount of tokens withdrawn.
     */
    function withdraw(address bond, uint256 amount) external returns (uint256);

    /**
     * @notice Emitted when tokens are deposited into a bond.
     * @param bond The address of the bond contract.
     * @param amount The amount of tokens deposited.
     * @param timestamp Timestamp of the deposit.
     */
    event DefaultBondModuleDeposit(
        address indexed bond,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when tokens are withdrawn from a bond.
     * @param bond The address of the bond contract.
     * @param amount The amount of tokens withdrawn.
     */
    event DefaultBondModuleWithdraw(address indexed bond, uint256 amount);
}
