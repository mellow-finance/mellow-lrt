// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IStakingRouter {
    struct StakingModule {
        /// @notice unique id of the staking module
        uint24 id;
        /// @notice address of staking module
        address stakingModuleAddress;
        /// @notice part of the fee taken from staking rewards that goes to the staking module
        uint16 stakingModuleFee;
        /// @notice part of the fee taken from staking rewards that goes to the treasury
        uint16 treasuryFee;
        /// @notice maximum stake share that can be allocated to a module, in BP
        uint16 stakeShareLimit; // formerly known as `targetShare`
        /// @notice staking module status if staking module can not accept the deposits or can participate in further reward distribution
        uint8 status;
        /// @notice name of staking module
        string name;
        /// @notice block.timestamp of the last deposit of the staking module
        /// @dev NB: lastDepositAt gets updated even if the deposit value was 0 and no actual deposit happened
        uint64 lastDepositAt;
        /// @notice block.number of the last deposit of the staking module
        /// @dev NB: lastDepositBlock gets updated even if the deposit value was 0 and no actual deposit happened
        uint256 lastDepositBlock;
        /// @notice number of exited validators
        uint256 exitedValidatorsCount;
        /// @notice module's share threshold, upon crossing which, exits of validators from the module will be prioritized, in BP
        uint16 priorityExitShareThreshold;
        /// @notice the maximum number of validators that can be deposited in a single block
        /// @dev must be harmonized with `OracleReportSanityChecker.appearedValidatorsPerDayLimit`
        /// (see docs for the `OracleReportSanityChecker.setAppearedValidatorsPerDayLimit` function)
        uint64 maxDepositsPerBlock;
        /// @notice the minimum distance between deposits in blocks
        /// @dev must be harmonized with `OracleReportSanityChecker.appearedValidatorsPerDayLimit`
        /// (see docs for the `OracleReportSanityChecker.setAppearedValidatorsPerDayLimit` function)
        uint64 minDepositBlockDistance;
    }

    function pauseStakingModule(uint256 _stakingModuleId) external;
    function resumeStakingModule(uint256 _stakingModuleId) external;
    function getStakingModuleIsDepositPaused(
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
    function getStakingModuleMaxDepositsCount(
        uint256 _stakingModuleId,
        uint256 depositableEther
    ) external view returns (uint256);
    function getStakingModuleMaxDepositsPerBlock(
        uint256 _stakingModuleId
    ) external view returns (uint256);
    function updateStakingModule(
        uint256 _stakingModuleId,
        uint256 _stakeShareLimit,
        uint256 _priorityExitShareThreshold,
        uint256 _stakingModuleFee,
        uint256 _treasuryFee,
        uint256 _maxDepositsPerBlock,
        uint256 _minDepositBlockDistance
    ) external;

    function getStakingModule(
        uint256 _stakingModuleId
    ) external view returns (StakingModule memory);
}
