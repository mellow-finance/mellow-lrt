// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/utils/IWethDepositWrapper.sol";

contract WethDepositWrapper is IWethDepositWrapper {
    using SafeERC20 for IERC20;

    /// @inheritdoc IWethDepositWrapper
    address public immutable weth;
    /// @inheritdoc IWethDepositWrapper
    IVault public immutable vault;

    constructor(IVault vault_, address weth_) {
        vault = vault_;
        weth = weth_;
    }

    /// @inheritdoc IWethDepositWrapper
    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 minLpAmount,
        uint256 deadline,
        uint256 referralCode
    ) external payable returns (uint256 lpAmount) {
        if (amount == 0) revert InvalidAmount();
        if (to == address(0)) revert AddressZero();
        address[] memory tokens = vault.underlyingTokens();
        uint256 wethIndex = tokens.length;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == weth) {
                wethIndex = i;
                break;
            }
        }
        if (wethIndex == tokens.length) revert InvalidTokenList();
        if (token == address(0)) {
            if (msg.value != amount) revert InvalidAmount();
            IWeth(weth).deposit{value: amount}();
            token = weth;
        } else if (token == weth) {
            if (msg.value != 0) revert InvalidAmount();
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            revert InvalidToken();
        }

        uint256[] memory amounts = new uint256[](tokens.length);
        amounts[wethIndex] = amount;
        IERC20(token).safeIncreaseAllowance(address(vault), amount);
        // if deposit ratiosX96[wethIndex] != Q96 -> vault.deposit function reverts
        (, lpAmount) = vault.deposit(
            to,
            amounts,
            minLpAmount,
            deadline,
            referralCode
        );

        emit WethDepositWrapperDeposit(
            msg.sender,
            token,
            amount,
            lpAmount,
            deadline
        );
    }
}
