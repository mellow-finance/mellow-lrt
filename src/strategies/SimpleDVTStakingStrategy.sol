// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../interfaces/strategies/ISimpleDVTStakingStrategy.sol";

import "../utils/DefaultAccessControl.sol";

contract SimpleDVTStakingStrategy is
    ISimpleDVTStakingStrategy,
    DefaultAccessControl
{
    /// @inheritdoc ISimpleDVTStakingStrategy
    IVault public immutable vault;
    /// @inheritdoc ISimpleDVTStakingStrategy
    IStakingModule public immutable stakingModule;
    /// @inheritdoc ISimpleDVTStakingStrategy
    uint256 public maxAllowedRemainder;

    constructor(
        address admin,
        IVault vault_,
        IStakingModule stakingModule_
    ) DefaultAccessControl(admin) {
        vault = vault_;
        stakingModule = stakingModule_;
    }

    /// @inheritdoc ISimpleDVTStakingStrategy
    function setMaxAllowedRemainder(uint256 newMaxAllowedRemainder) external {
        _requireAdmin();
        maxAllowedRemainder = newMaxAllowedRemainder;
        emit MaxAllowedRemainderChanged(newMaxAllowedRemainder, msg.sender);
    }

    /// @inheritdoc ISimpleDVTStakingStrategy
    function convertAndDeposit(
        uint256 amount,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 nonce,
        bytes calldata depositCalldata,
        IDepositSecurityModule.Signature[] calldata sortedGuardianSignatures
    ) external returns (bool success) {
        _requireAtLeastOperator();
        (success, ) = vault.delegateCall(
            address(stakingModule),
            abi.encodeWithSelector(
                IStakingModule.convertAndDeposit.selector,
                amount,
                blockNumber,
                blockHash,
                depositRoot,
                nonce,
                depositCalldata,
                sortedGuardianSignatures
            )
        );
        emit ConvertAndDeposit(success, msg.sender);
    }

    /// @inheritdoc ISimpleDVTStakingStrategy
    function processWithdrawals(
        address[] memory users,
        uint256 amountForStake
    ) external returns (bool[] memory statuses) {
        _requireAtLeastOperator();
        if (users.length == 0) return statuses;
        emit ProcessWithdrawals(users, amountForStake, msg.sender);

        if (amountForStake == 0) return vault.processWithdrawals(users);

        vault.delegateCall(
            address(stakingModule),
            abi.encodeWithSelector(
                IStakingModule.convert.selector,
                amountForStake
            )
        );

        statuses = vault.processWithdrawals(users);
        address wsteth = stakingModule.wsteth();
        uint256 balance = IERC20(wsteth).balanceOf(address(vault));
        if (balance > maxAllowedRemainder) revert LimitOverflow();
    }
}
