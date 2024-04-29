// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISteth {
    function submit(address _referral) external payable returns (uint256);
}
