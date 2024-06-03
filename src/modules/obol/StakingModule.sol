// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../interfaces/modules/obol/IStakingModule.sol";

import "../DefaultModule.sol";

contract StakingModule is IStakingModule, DefaultModule {
    using SafeERC20 for IERC20;

    /// @inheritdoc IStakingModule
    address public immutable weth;
    /// @inheritdoc IStakingModule
    address public immutable steth;
    /// @inheritdoc IStakingModule
    address public immutable wsteth;

    /// @inheritdoc IStakingModule
    IDepositSecurityModule public immutable depositSecurityModule;
    /// @inheritdoc IStakingModule
    IWithdrawalQueue public immutable withdrawalQueue;

    /// @inheritdoc IStakingModule
    uint256 public immutable stakingModuleId;

    constructor(
        address weth_,
        address steth_,
        address wsteth_,
        IDepositSecurityModule depositSecurityModule_,
        IWithdrawalQueue withdrawalQueue_,
        uint256 stakingModuleId_
    ) {
        weth = weth_;
        steth = steth_;
        wsteth = wsteth_;
        depositSecurityModule = depositSecurityModule_;
        withdrawalQueue = withdrawalQueue_;
        stakingModuleId = stakingModuleId_;
    }

    /// @inheritdoc IStakingModule
    function convert(uint256 amount) external onlyDelegateCall {
        _wethToWSteth(amount);
    }

    /// @inheritdoc IStakingModule
    function convertAndDeposit(
        uint256,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 nonce,
        bytes calldata depositCalldata,
        IDepositSecurityModule.Signature[] calldata sortedGuardianSignatures
    ) external onlyDelegateCall {
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        uint256 unfinalizedStETH = withdrawalQueue.unfinalizedStETH();
        uint256 bufferedEther = ISteth(steth).getBufferedEther();
        if (bufferedEther < unfinalizedStETH)
            revert InvalidWithdrawalQueueState();
        uint256 maxDepositsCount = Math.min(
            IStakingRouter(depositSecurityModule.STAKING_ROUTER())
                .getStakingModuleMaxDepositsCount(
                    stakingModuleId,
                    wethBalance + bufferedEther - unfinalizedStETH
                ),
            depositSecurityModule.getMaxDeposits()
        );
        uint256 amount = Math.min(
            wethBalance,
            ISteth(steth).DEPOSIT_SIZE() * maxDepositsCount
        );
        if (amount == 0) revert InvalidAmount();
        _wethToWSteth(amount);
        depositSecurityModule.depositBufferedEther(
            blockNumber,
            blockHash,
            depositRoot,
            stakingModuleId,
            nonce,
            depositCalldata,
            sortedGuardianSignatures
        );
        emit DepositCompleted(amount, blockNumber);
    }

    function _wethToWSteth(uint256 amount) private {
        IWeth(weth).withdraw(amount);
        ISteth(steth).submit{value: amount}(address(0));
        IERC20(steth).safeIncreaseAllowance(address(wsteth), amount);
        IWSteth(wsteth).wrap(amount);
        emit Converted(amount);
    }
}
