// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/strategies/IDefaultObolStakingStrategy.sol";

import "../utils/DefaultAccessControl.sol";

contract DefaultObolStakingStrategy is
    IDefaultObolStakingStrategy,
    DefaultAccessControl
{
    /// @inheritdoc IDefaultObolStakingStrategy
    IVault public immutable vault;
    /// @inheritdoc IDefaultObolStakingStrategy
    IStakingModule public immutable stakingModule;
    /// @inheritdoc IDefaultObolStakingStrategy
    uint256 public maxAllowedRemainder;

    constructor(
        address admin,
        IVault vault_,
        IStakingModule stakingModule_
    ) DefaultAccessControl(admin) {
        vault = vault_;
        stakingModule = stakingModule_;
    }

    /// @inheritdoc IDefaultObolStakingStrategy
    function setMaxAllowedRemainder(uint256 newMaxAllowedRemainder) external {
        _requireAdmin();
        maxAllowedRemainder = newMaxAllowedRemainder;
        emit MaxAllowedRemainderChanged(newMaxAllowedRemainder, msg.sender);
    }

    /// @inheritdoc IDefaultObolStakingStrategy
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
    }

    /// @inheritdoc IDefaultObolStakingStrategy
    function processWithdrawals(
        address[] memory users,
        uint256 amountForStake
    ) external {
        _requireAtLeastOperator();
        if (users.length == 0) return;

        if (amountForStake == 0) {
            vault.processWithdrawals(users);
            return;
        }

        vault.delegateCall(
            address(stakingModule),
            abi.encodeWithSelector(
                IStakingModule.convert.selector,
                amountForStake
            )
        );

        vault.processWithdrawals(users);

        address wsteth = stakingModule.wsteth();
        uint256 balance = IERC20(wsteth).balanceOf(address(vault));
        if (balance > maxAllowedRemainder) revert LimitOverflow();
    }
}
