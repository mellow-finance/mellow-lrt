// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../../src/interfaces/utils/IDepositCallback.sol";

contract DepositCallbackMock is IDepositCallback {
    function testMock() public {}

    bool public flag = false;

    function depositCallback(uint256[] memory, uint256) external {
        flag = true;
    }
}
