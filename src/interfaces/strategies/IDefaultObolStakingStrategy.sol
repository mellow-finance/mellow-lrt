// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../modules/obol/IStakingModule.sol";
import "../IVault.sol";

interface IDefaultObolStakingStrategy {
    error LimitOverflow();

    function vault() external view returns (IVault);

    function stakingModule() external view returns (IStakingModule);

    function processWithdrawals(
        address[] memory users,
        uint256 amountForStake
    ) external;

    event MaxAllowedRemainderChanged(
        uint256 newMaxAllowedRemainder,
        address indexed changer
    );
}
