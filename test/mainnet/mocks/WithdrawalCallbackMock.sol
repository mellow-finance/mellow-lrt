// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.21;

import "../../../src/interfaces/utils/IWithdrawalCallback.sol";

contract WithdrawalCallbackMock is IWithdrawalCallback {
    function testMock() public {}

    bool public flag = false;

    function withdrawalCallback() external {
        flag = true;
    }
}
