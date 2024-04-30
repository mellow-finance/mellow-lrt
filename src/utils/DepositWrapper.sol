// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/external/lido/ISteth.sol";
import "../interfaces/external/lido/IWeth.sol";
import "../interfaces/external/lido/IWSteth.sol";

import "../interfaces/IVault.sol";

contract WstethDepositWrapper {
    using SafeERC20 for IERC20;

    address public immutable weth;
    address public immutable steth;
    address public immutable wsteth;

    IVault public immutable vault;

    constructor(IVault vault_, address weth_, address steth_, address wsteth_) {
        vault = vault_;
        weth = weth_;
        steth = steth_;
        wsteth = wsteth_;
    }

    function _wethToWsteth(uint256 amount) internal returns (uint256) {
        IWeth(weth).withdraw(amount);
        return _ethToWsteth(amount);
    }

    function _ethToWsteth(uint256 amount) internal returns (uint256) {
        ISteth(steth).submit{value: amount}(address(0));
        return _stethToWsteth(amount);
    }

    function _stethToWsteth(uint256 amount) internal returns (uint256) {
        IERC20(steth).safeIncreaseAllowance(wsteth, amount);
        IWSteth(wsteth).wrap(amount);
        return IERC20(wsteth).balanceOf(address(this));
    }

    function _claim() private {
        address wrapper = address(this);
        address recipient = msg.sender;
        uint256 balance = IERC20(address(vault)).balanceOf(wrapper);
        if (balance > 0)
            IERC20(address(vault)).safeTransfer(recipient, balance);
        balance = IERC20(weth).balanceOf(wrapper);
        if (balance > 0) IERC20(weth).safeTransfer(recipient, balance);
        balance = IERC20(steth).balanceOf(wrapper);
        if (balance > 0) IERC20(steth).safeTransfer(recipient, balance);
        balance = IERC20(wsteth).balanceOf(wrapper);
        if (balance > 0) IERC20(wsteth).safeTransfer(recipient, balance);
        balance = wrapper.balance;
        if (balance > 0) payable(tx.origin).transfer(balance);
    }

    function deposit(
        address token,
        uint256 amount,
        uint256 minLpAmount,
        uint256 deadline
    ) public payable {
        address[] memory tokens = vault.underlyingTokens();
        if (tokens.length != 1 || tokens[0] != wsteth)
            revert("Invalid token list");
        if (amount == 0) revert("Invalid amount");
        if (token == steth) {
            IERC20(steth).safeTransferFrom(msg.sender, address(this), amount);
            amount = _stethToWsteth(amount);
        } else if (token == weth) {
            IERC20(weth).safeTransferFrom(msg.sender, address(this), amount);
            amount = _wethToWsteth(amount);
        } else if (token == address(0)) {
            require(msg.value == amount, "Invalid amount");
            amount = _ethToWsteth(amount);
        } else if (wsteth == token) {
            IERC20(wsteth).safeTransferFrom(msg.sender, address(this), amount);
        } else revert("Invalid token");

        IERC20(wsteth).safeIncreaseAllowance(address(vault), amount);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        vault.deposit(amounts, minLpAmount, deadline);
        _claim();
    }

    receive() external payable {
        if (msg.sender != address(weth)) revert("Invalid sender");
    }
}
