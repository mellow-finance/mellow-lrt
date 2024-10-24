// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../Vault.sol";

contract DVstETHOpeartor {
    Vault public immutable vault =
        Vault(payable(0x5E362eb2c0706Bd1d134689eC75176018385430B));

    function process() external {
        address[] memory users = new address[](1);
        users[0] = msg.sender;
        IVault.WithdrawalRequest memory withdrawalRequest = vault
            .withdrawalRequest(users[0]);
        if (
            withdrawalRequest.timestamp == 0 ||
            withdrawalRequest.timestamp == block.timestamp
        ) {
            revert("DVstETHOpeartor: invalid state");
        }
        bool[] memory statuses = vault.processWithdrawals(users);
        require(statuses[0], "DVstETHOpeartor: withdrawal failed");
    }
}
