// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositCallback {
    function depositCallback(
        uint256[] memory actualAmounts,
        uint256 lpAmount
    ) external;
}
