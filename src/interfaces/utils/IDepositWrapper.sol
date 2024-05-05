// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../external/lido/IWeth.sol";
import "../external/lido/ISteth.sol";
import "../external/lido/IWSteth.sol";

import "../IVault.sol";

interface IDepositWrapper {
    error AddressZero();
    error InvalidToken();
    error InvalidAmount();
    error InvalidTokenList();
    error InvalidSender();

    function weth() external view returns (address);
    function steth() external view returns (address);
    function wsteth() external view returns (address);
    function vault() external view returns (IVault);

    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 minLpAmount,
        uint256 deadline
    ) external payable returns (uint256 lpAmount);
}
