// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IStakingRouter {
    function pauseStakingModule(uint256 _stakingModuleId) external;
    function resumeStakingModule(uint256 _stakingModuleId) external;
    function getStakingModuleIsDepositsPaused(
        uint256 _stakingModuleId
    ) external view returns (bool);
    function getStakingModuleIsActive(
        uint256 _stakingModuleId
    ) external view returns (bool);
    function getStakingModuleNonce(
        uint256 _stakingModuleId
    ) external view returns (uint256);
    function getStakingModuleLastDepositBlock(
        uint256 _stakingModuleId
    ) external view returns (uint256);
    function hasStakingModule(
        uint256 _stakingModuleId
    ) external view returns (bool);
}
