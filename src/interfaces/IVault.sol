// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";

import "./modules/ITvlModule.sol";
import "./validators/IValidator.sol";

import "./oracles/IOracle.sol";
import "./oracles/IRatiosOracle.sol";

import "./utils/IDepositCallback.sol";
import "./utils/IWithdrawalCallback.sol";

import "./IProtocolGovernance.sol";

interface IVault {
    error Deadline();
    error InvalidLength();
    error InvalidToken();
    error InvalidState();
    error InsufficientLpAmount();
    error LimitOverflow();
    error NonZeroValue();

    struct WithdrawalRequest {
        address to;
        uint256 lpAmount;
        uint256 deadline;
        address[] tokens;
        uint256[] minAmounts;
    }

    // for stack reduction
    struct ProcessWithdrawalsStorage {
        uint256 totalValue;
        uint256 x96Value;
        uint256[] ratiosX96;
        uint256[] amounts;
    }

    function Q96() external view returns (uint256);

    function D9() external view returns (uint256);

    function ratiosOracle() external view returns (IRatiosOracle);

    function oracle() external view returns (IOracle);

    function validator() external view returns (IValidator);

    function protocolGovernance() external view returns (IProtocolGovernance);

    function tvlModuleParams(address) external view returns (bytes memory);

    function withdrawalRequest(
        address
    ) external view returns (WithdrawalRequest memory);

    function withdrawers() external view returns (address[] memory);

    function tvlModules() external view returns (address[] memory);

    function addToken(address token) external;

    function removeToken(address token) external;

    function setTvlModule(address module, bytes memory params) external;

    function removeTvlModule(address module) external;

    function externalCall(
        address to,
        bytes calldata data
    ) external returns (bytes memory);

    function delegateCall(
        address to,
        bytes calldata data
    ) external returns (bytes memory);

    function underlyingTokens() external view returns (address[] memory);

    function tvl()
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    function deposit(
        uint256[] memory amounts,
        uint256 minLpAmount,
        uint256 deadline
    ) external returns (uint256[] memory actualAmounts, uint256 lpAmount);

    function closeWithdrawalRequest() external;

    function registerWithdrawal(
        address to,
        uint256 lpAmount,
        uint256[] memory minAmounts,
        uint256 deadline
    ) external;

    function processWithdrawals(
        address[] memory users
    ) external returns (bool[] memory statuses);
}
