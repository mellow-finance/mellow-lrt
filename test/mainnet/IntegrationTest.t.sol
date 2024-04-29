// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./Fixture.sol";

contract Integration is Fixture {
    using SafeERC20 for IERC20;

    function test() external {
        vm.startPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);

        address[] memory tokens = new address[](1);
        tokens[0] = Constants.STETH;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 1 ether;

        ratiosOracle.updateRatios(address(vault), tokens, weights);

        protocolGovernance.stageMaximalTotalSupply(
            address(vault),
            type(uint256).max
        );
        protocolGovernance.commitMaximalTotalSupply(address(vault));

        newPrank(Constants.VAULT_ADMIN);
        vault.addToken(Constants.STETH);
        vault.setTvlModule(address(erc20TvlModule), new bytes(0));

        // initial deposit
        newPrank(address(this));
        mintSteth(address(this), 10 ether);
        mintSteth(Constants.DEPOSITOR, 10 ether);
        {
            uint256 amount = 10 gwei;
            IERC20(Constants.STETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            vault.deposit(amounts, amount);
        }

        // normal deposit
        newPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 10 ether;
            IERC20(Constants.STETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            vault.deposit(amounts, amount);
        }

        console2.log(
            "Depositor balances before:",
            vault.balanceOf(Constants.DEPOSITOR),
            IERC20(Constants.STETH).balanceOf(Constants.DEPOSITOR)
        );

        vault.registerWithdrawal(
            Constants.DEPOSITOR,
            vault.balanceOf(Constants.DEPOSITOR) / 2,
            new uint256[](1),
            type(uint256).max
        );

        newPrank(Constants.VAULT_ADMIN);
        {
            address[] memory users = new address[](1);
            users[0] = Constants.DEPOSITOR;
            bool[] memory statuses = vault.processWithdrawals(users);
            console2.log("Withdrawal status:", vm.toString(statuses[0]));
        }

        console2.log(
            "Depositor balances after:",
            vault.balanceOf(Constants.DEPOSITOR),
            IERC20(Constants.STETH).balanceOf(Constants.DEPOSITOR)
        );

        newPrank(Constants.VAULT_ADMIN);
        vm.expectRevert("Vault: token has non-zero balance");
        vault.removeToken(Constants.STETH);

        vm.stopPrank();
        // assert(false);
    }
}
