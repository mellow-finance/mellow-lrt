// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "./StakingModule.sol";

interface IMutableStakingModule {
    function getAmountForPermissionlessStake()
        external
        view
        returns (uint256 amount);

    function getAmountForStakeAndDeposit(
        bytes calldata data
    ) external view returns (uint256);

    function depositOnBehalf(
        bytes calldata data,
        uint256 submitted,
        address sender
    ) external;
}

contract MutableStakingModule is IMutableStakingModule {
    function getAmountForPermissionlessStake()
        external
        pure
        returns (uint256)
    {}

    function getAmountForStakeAndDeposit(
        bytes calldata data
    ) external view returns (uint256) {}

    function depositOnBehalf(
        bytes calldata data,
        uint256 submitted,
        address sender
    ) external {}
}
