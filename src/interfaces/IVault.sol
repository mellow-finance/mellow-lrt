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
        bytes32 tokensHash;
        uint256[] minAmounts;
    }

    struct ProcessWithdrawalsStack {
        uint256 totalValue;
        uint256 totalSupply;
        uint256 ratiosX96Value;
        uint256 timestamp;
        uint256 feeD9;
        bytes32 tokensHash;
        address[] tokens;
        uint128[] ratiosX96;
        uint256[] erc20Balances;
    }

    function Q96() external view returns (uint256);

    function D9() external view returns (uint256);

    function configurator() external view returns (IVaultConfigurator);

    function withdrawalRequest(
        address
    ) external view returns (WithdrawalRequest memory);

    function pendingWithdrawers() external view returns (address[] memory);

    function tvlModules() external view returns (address[] memory);

    function addToken(address token) external;

    function removeToken(address token) external;

    function addTvlModule(address module) external;

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

    function underlyingTvl()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function deposit(
        address to,
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256 deadline
    ) external returns (uint256[] memory actualAmounts, uint256 lpAmount);

    function cancelWithdrawalRequest() external;

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 deadline,
        uint256 requestDeadline,
        bool closePrevious
    ) external;

    function processWithdrawals(
        address[] memory users
    ) external returns (bool[] memory statuses);

    function analyzeRequest(
        ProcessWithdrawalsStack memory s,
        WithdrawalRequest memory request
    ) external view returns (bool, bool, uint256[] memory expectedAmounts);

    function calculateStack()
        external
        view
        returns (ProcessWithdrawalsStack memory s);

    function baseTvl()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function emergencyWithdraw(
        uint256[] memory minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory actualAmounts);

    event WithdrawalProcessed(
        address indexed user,
        uint256 lpAmount,
        uint256[] amounts
    );

    event TokenAdded(address indexed token);

    event TokenRemoved(address indexed token);

    event TvlModuleAdded(address indexed module);

    event TvlModuleRemoved(address indexed module);

    event ExternalCall(
        address indexed to,
        bytes data,
        bool success,
        bytes result
    );

    event DelegateCall(
        address indexed to,
        bytes data,
        bool success,
        bytes result
    );

    event Deposit(
        address indexed to,
        uint256[] actualAmounts,
        uint256 lpAmount
    );

    event WithdrawalsProcessed(address[] users, bool[] statuses);

    event WithdrawCallback(address callback);

    event DepositCallback(
        address callback,
        uint256[] amounts,
        uint256 lpAmount
    );

    event WithdrawalRequestCanceled(
        address indexed user,
        address indexed origin
    );

    event WithdrawalRequested(address indexed user, WithdrawalRequest request);

    event EmergencyWithdrawal(
        address indexed sender,
        WithdrawalRequest request,
        uint256[] actualAmounts
    );
}
