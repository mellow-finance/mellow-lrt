// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

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
    uint256 public immutable simpleDVTModuleId;

    constructor(
        address weth_,
        address steth_,
        address wsteth_,
        IDepositSecurityModule depositSecurityModule_,
        IWithdrawalQueue withdrawalQueue_,
        uint256 simpleDVTModuleId_
    ) {
        weth = weth_;
        steth = steth_;
        wsteth = wsteth_;
        depositSecurityModule = depositSecurityModule_;
        withdrawalQueue = withdrawalQueue_;
        simpleDVTModuleId = simpleDVTModuleId_;
    }

    /// @inheritdoc IStakingModule
    function convert(uint256 amount) external onlyDelegateCall {
        _wethToSteth(amount);
        _stethToWsteth(amount);
    }

    /// @inheritdoc IStakingModule
    function convertAndDeposit(
        uint256 amount,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 nonce,
        bytes calldata depositCalldata,
        IDepositSecurityModule.Signature[] calldata sortedGuardianSignatures
    ) external onlyDelegateCall {
        if (IERC20(weth).balanceOf(address(this)) < amount)
            revert NotEnoughWeth();

        uint256 unfinalizedStETH = withdrawalQueue.unfinalizedStETH();
        uint256 bufferedEther = ISteth(steth).getBufferedEther();
        if (bufferedEther < unfinalizedStETH)
            revert InvalidWithdrawalQueueState();

        _wethToSteth(amount);
        depositSecurityModule.depositBufferedEther(
            blockNumber,
            blockHash,
            depositRoot,
            simpleDVTModuleId,
            nonce,
            depositCalldata,
            sortedGuardianSignatures
        );
        _stethToWsteth(amount);
    }

    function _wethToSteth(uint256 amount) private {
        IWeth(weth).withdraw(amount);
        ISteth(steth).submit{value: amount}(address(0));
    }

    function _stethToWsteth(uint256 amount) private {
        IERC20(steth).safeIncreaseAllowance(address(wsteth), amount);
        IWSteth(wsteth).wrap(amount);
    }
}
