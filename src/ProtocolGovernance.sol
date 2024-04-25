// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ProtocolGovernance is ReentrancyGuard {
    address public immutable admin;
    uint256 public immutable governanceDelay;

    mapping(address => uint256) public delegateModulesStageTimestamps;
    mapping(address => bool) public approvedDelegateModules;

    mapping(address => uint256) public stagedMaxTotalSupplyTimestamp;
    mapping(address => uint256) public stagedMaxTotalSupply;
    mapping(address => uint256) public maxTotalSupply;

    mapping(address => address) public stagedDepositCallback;
    mapping(address => uint256) public stagedDepositCallbackTimestamp;
    mapping(address => address) public depositCallback;

    mapping(address => address) public stagedWithdrawalCallback;
    mapping(address => uint256) public stagedWithdrawalCallbackTimestamp;
    mapping(address => address) public withdrawalCallback;

    modifier onlyAdmin() {
        if (msg.sender != admin)
            revert("ProtocolGovernance: caller is not the admin");
        _;
    }

    constructor(address admin_, uint256 governanceDelay_) {
        if (admin_ == address(0)) revert("ProtocolGovernance: invalid admin");
        if (governanceDelay_ == 0 || governanceDelay_ > 30 days)
            revert("ProtocolGovernance: invalid governance delay");
        admin = admin_;
        governanceDelay = governanceDelay_;
    }

    function revokeDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        delete delegateModulesStageTimestamps[module];
        delete approvedDelegateModules[module];
    }

    function stageDelegateModuleApproval(
        address module
    ) external onlyAdmin nonReentrant {
        delegateModulesStageTimestamps[module] = block.timestamp;
    }

    function commitDelegateModuleApproval(
        address module,
        bool approved
    ) external onlyAdmin nonReentrant {
        if (delegateModulesStageTimestamps[module] == 0)
            revert("ProtocolGovernance: module is not staged for approval");
        if (
            block.timestamp - delegateModulesStageTimestamps[module] <
            governanceDelay
        ) revert("ProtocolGovernance: stage delay has not passed");
        approvedDelegateModules[module] = approved;
    }

    function stageMaximalTotalSupply(
        address vault,
        uint256 totalSupply
    ) external onlyAdmin nonReentrant {
        stagedMaxTotalSupplyTimestamp[vault] = block.timestamp;
        stagedMaxTotalSupply[vault] = totalSupply;
    }

    function commitMaximalTotalSupply(
        address vault
    ) external onlyAdmin nonReentrant {
        if (stagedMaxTotalSupplyTimestamp[vault] == 0)
            revert(
                "ProtocolGovernance: vault is not staged for maximal total supply"
            );
        if (
            block.timestamp - stagedMaxTotalSupplyTimestamp[vault] <
            governanceDelay
        ) revert("ProtocolGovernance: stage delay has not passed");
        maxTotalSupply[vault] = stagedMaxTotalSupply[vault];
    }

    function revokeMaximalTotalSupply(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedMaxTotalSupplyTimestamp[vault];
        delete stagedMaxTotalSupply[vault];
    }

    function stageDepositCallback(
        address vault,
        address callback
    ) external onlyAdmin nonReentrant {
        stagedDepositCallbackTimestamp[vault] = block.timestamp;
        stagedDepositCallback[vault] = callback;
    }

    function commitDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        if (stagedDepositCallbackTimestamp[vault] == 0)
            revert(
                "ProtocolGovernance: vault is not staged for deposit callback"
            );
        if (
            block.timestamp - stagedDepositCallbackTimestamp[vault] <
            governanceDelay
        ) revert("ProtocolGovernance: stage delay has not passed");
        depositCallback[vault] = stagedDepositCallback[vault];
    }

    function revokeDepositCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedDepositCallbackTimestamp[vault];
        delete stagedDepositCallback[vault];
    }

    function stageWithdrawalCallback(
        address vault,
        address callback
    ) external onlyAdmin nonReentrant {
        stagedWithdrawalCallbackTimestamp[vault] = block.timestamp;
        stagedWithdrawalCallback[vault] = callback;
    }

    function commitWithdrawalCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        if (stagedWithdrawalCallbackTimestamp[vault] == 0)
            revert(
                "ProtocolGovernance: vault is not staged for withdrawal callback"
            );
        if (
            block.timestamp - stagedWithdrawalCallbackTimestamp[vault] <
            governanceDelay
        ) revert("ProtocolGovernance: stage delay has not passed");
        withdrawalCallback[vault] = stagedWithdrawalCallback[vault];
    }

    function revokeWithdrawalCallback(
        address vault
    ) external onlyAdmin nonReentrant {
        delete stagedWithdrawalCallbackTimestamp[vault];
        delete stagedWithdrawalCallback[vault];
    }
}
