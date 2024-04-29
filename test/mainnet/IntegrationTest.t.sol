// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./Fixture.sol";

contract Integration is Fixture {
    using SafeERC20 for IERC20;

    function _initializeVault() private {
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

        protocolGovernance.stageDelegateModuleApproval(
            address(bondDepositModule)
        );
        protocolGovernance.stageDelegateModuleApproval(
            address(bondWithdrawalModule)
        );
        protocolGovernance.commitDelegateModuleApproval(
            address(bondDepositModule)
        );
        protocolGovernance.commitDelegateModuleApproval(
            address(bondWithdrawalModule)
        );

        validator.grantRole(address(vault), Constants.DEFAULT_BOND_ROLE);
        validator.grantContractRole(
            address(bondDepositModule),
            Constants.DEFAULT_BOND_ROLE
        );
        validator.grantContractRole(
            address(bondWithdrawalModule),
            Constants.DEFAULT_BOND_ROLE
        );
        validator.setCustomValidator(
            address(bondDepositModule),
            address(customValidator)
        );
        validator.setCustomValidator(
            address(bondWithdrawalModule),
            address(customValidator)
        );
        customValidator.addSupported(address(stethDefaultBond));

        newPrank(Constants.VAULT_ADMIN);
        vault.addToken(Constants.STETH);
        vault.setTvlModule(address(erc20TvlModule), new bytes(0));
        address[] memory bonds = new address[](1);
        bonds[0] = address(stethDefaultBond);
        vault.setTvlModule(
            address(bondTvlModule),
            abi.encode(DefaultBondTvlModule.Params({bonds: bonds}))
        );

        // initial deposit
        newPrank(address(this));
        mintSteth(address(this), 10 ether);
        mintSteth(Constants.DEPOSITOR, 10 ether);
    }

    function _initialDeposit() private {
        uint256 amount = 10 gwei;
        IERC20(Constants.STETH).safeIncreaseAllowance(address(vault), amount);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        vault.deposit(amounts, amount, type(uint256).max);
    }

    function testPrimitiveOperations() external {
        _initializeVault();
        _initialDeposit();

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
            vault.deposit(amounts, amount, type(uint256).max);
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
        vm.expectRevert(abi.encodeWithSignature("NonZeroValue()"));
        vault.removeToken(Constants.STETH);

        vm.stopPrank();
        // assert(false);
    }

    function testDepositCallback() external {
        _initializeVault();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            Constants.PROTOCOL_GOVERNANCE_ADMIN,
            vault,
            erc20TvlModule,
            bondDepositModule,
            bondWithdrawalModule
        );

        newPrank(Constants.VAULT_ADMIN);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        vault.grantRole(vault.OPERATOR(), address(strategy));

        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);

        {
            DefaultBondStrategy.Data[]
                memory data = new DefaultBondStrategy.Data[](1);
            data[0] = DefaultBondStrategy.Data({
                bond: address(stethDefaultBond),
                ratioX96: Q96
            });
            strategy.setData(Constants.STETH, data);
        }
        protocolGovernance.stageDepositCallback(
            address(vault),
            address(strategy)
        );
        protocolGovernance.commitDepositCallback(address(vault));

        newPrank(address(this));
        _initialDeposit();

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
            vault.deposit(amounts, amount, type(uint256).max);
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
            // assertFalse(statuses[0]);
        }

        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        strategy.processAll();

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

        vm.stopPrank();
        // assert(false);
    }
}
