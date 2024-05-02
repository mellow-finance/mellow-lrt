// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

import "./modules/ITvlModule.sol";
import "./validators/IValidator.sol";

import "./oracles/IPriceOracle.sol";
import "./oracles/IRatiosOracle.sol";

import "./utils/IDepositCallback.sol";
import "./utils/IWithdrawalCallback.sol";

import "./IVaultConfigurator.sol";

interface IVault {
    error Deadline();
    error InvalidLength();
    error InvalidToken();
    error InvalidState();
    error InsufficientLpAmount();
    error InsufficientAmount();
    error LimitOverflow();
    error NonZeroValue();
    error ValueZero();

    struct WithdrawalRequest {
        address to;
        uint256 lpAmount;
        uint256 deadline;
        uint256 timestamp;
        address[] tokens;
        uint256[] minAmounts;
    }

    struct ProcessWithdrawalsStack {
        uint256 totalValue;
        uint256 ratiosX96Value;
        uint128[] ratiosX96;
        uint256[] amounts;
    }

    function Q96() external view returns (uint256);

    function D9() external view returns (uint256);

    function ratiosOracle() external view returns (IRatiosOracle);

    function priceOracle() external view returns (IPriceOracle);

    function validator() external view returns (IValidator);

    function configurator() external view returns (IVaultConfigurator);

    function withdrawalRequest(
        address
    ) external view returns (WithdrawalRequest memory);

    function pendingWithdrawers() external view returns (address[] memory);

    function tvlModules() external view returns (address[] memory);

    function addToken(address token) external;

    function removeToken(address token) external;

    function setTvlModule(address module) external;

    function removeTvlModule(address module) external;

    function externalCall(
        address to,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function delegateCall(
        address to,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function underlyingTokens() external view returns (address[] memory);

    function tvl()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function deposit(
        address to,
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256 deadline
    ) external returns (uint256[] memory actualAmounts, uint256 lpAmount);

    function cancleWithdrawalRequest() external;

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 deadline,
        bool closePrevious
    ) external;

    function processWithdrawals(
        address[] memory users
    ) external returns (bool[] memory statuses);

    function isUnderlyingToken(address token) external view returns (bool);
}
