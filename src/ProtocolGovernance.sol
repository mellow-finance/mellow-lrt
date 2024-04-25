// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ProtocolGovernance is ReentrancyGuard {
    address public immutable admin;
    uint256 public immutable governanceDelay;

    mapping(address => uint256) public delegateModulesStageTimestamps;
    mapping(address => bool) public approvedDelegateModules;

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
}
