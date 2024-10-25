// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {IVault} from "../interfaces/IVault.sol";

contract DVstETHOpeartor {
    IVault public constant vault =
        IVault(0x5E362eb2c0706Bd1d134689eC75176018385430B);

    function process(address[] calldata users) external {
        uint256 latestTimestamp = block.timestamp - 1 hours;
        for (uint256 i = 0; i < users.length; i++) {
            uint256 timestamp = vault.withdrawalRequest(users[i]).timestamp;
            if (timestamp == 0 || timestamp > latestTimestamp) {
                revert("DVstETHOpeartor: invalid withdrawal requets timestamp");
            }
        }
        vault.processWithdrawals(users);
    }
}
