// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../scripts/mainnet/DeployInterfaces.sol";

contract HoleskyDeployer2 {
    using SafeERC20 for IERC20;

    function deploy(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory s
    )
        external
        payable
        returns (
            DeployInterfaces.DeployParameters memory,
            DeployInterfaces.DeploySetup memory
        )
    {
        require(address(this) == deployParams.deployer, "Invalid deployer"); // delegate call only
        {
            s.validator.grantContractRole(
                address(deployParams.defaultBondModule),
                DeployConstants.DEFAULT_BOND_MODULE_ROLE_BIT
            );

            s.validator.grantPublicRole(DeployConstants.DEPOSITOR_ROLE_BIT);
            s.validator.grantContractSignatureRole(
                address(s.vault),
                IVault.deposit.selector,
                DeployConstants.DEPOSITOR_ROLE_BIT
            );

            s.configurator.stageValidator(address(s.validator));
            s.configurator.commitValidator();
        }

        s.vault.grantRole(s.vault.OPERATOR(), address(s.defaultBondStrategy));

        s.depositWrapper = new DepositWrapper(
            s.vault,
            deployParams.weth,
            deployParams.steth,
            deployParams.wsteth
        );

        // setting all configurator
        {
            s.configurator.stageDepositCallbackDelay(1 days);
            s.configurator.commitDepositCallbackDelay();

            s.configurator.stageWithdrawalCallbackDelay(1 days);
            s.configurator.commitWithdrawalCallbackDelay();

            s.configurator.stageWithdrawalFeeD9Delay(30 days);
            s.configurator.commitWithdrawalFeeD9Delay();

            s.configurator.stageMaximalTotalSupplyDelay(1 days);
            s.configurator.commitMaximalTotalSupplyDelay();

            s.configurator.stageDepositsLockedDelay(1 hours);
            s.configurator.commitDepositsLockedDelay();

            s.configurator.stageTransfersLockedDelay(365 days);
            s.configurator.commitTransfersLockedDelay();

            s.configurator.stageDelegateModuleApprovalDelay(1 days);
            s.configurator.commitDelegateModuleApprovalDelay();

            s.configurator.stageRatiosOracleDelay(30 days);
            s.configurator.commitRatiosOracleDelay();

            s.configurator.stagePriceOracleDelay(30 days);
            s.configurator.commitPriceOracleDelay();

            s.configurator.stageValidatorDelay(30 days);
            s.configurator.commitValidatorDelay();

            s.configurator.stageEmergencyWithdrawalDelay(90 days);
            s.configurator.commitEmergencyWithdrawalDelay();

            s.configurator.stageBaseDelay(30 days);
            s.configurator.commitBaseDelay();
        }

        // initial deposit
        {
            require(
                deployParams.initialDepositETH > 0,
                "Invalid deploy params. Initial deposit value is 0"
            );
            require(
                deployParams.deployer.balance >= deployParams.initialDepositETH,
                "Insufficient ETH amount for deposit"
            );
            // eth -> steth -> wsteth
            uint256 initialWstethAmount = IERC20(deployParams.wsteth).balanceOf(
                deployParams.deployer
            );
            ISteth(deployParams.steth).submit{
                value: deployParams.initialDepositETH
            }(address(0));
            IERC20(deployParams.steth).safeIncreaseAllowance(
                deployParams.wsteth,
                deployParams.initialDepositETH
            );
            IWSteth(deployParams.wsteth).wrap(deployParams.initialDepositETH);
            uint256 wstethAmount = IERC20(deployParams.wsteth).balanceOf(
                deployParams.deployer
            ) - initialWstethAmount;
            IERC20(deployParams.wsteth).safeIncreaseAllowance(
                address(s.vault),
                wstethAmount
            );
            require(wstethAmount > 0, "No wsteth received");
            address[] memory tokens = new address[](1);
            tokens[0] = deployParams.wsteth;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = wstethAmount;
            s.vault.deposit(
                address(s.vault),
                amounts,
                wstethAmount,
                type(uint256).max
            );
            s.wstethAmountDeposited = wstethAmount;
        }

        s.vault.renounceRole(s.vault.ADMIN_ROLE(), deployParams.deployer);
        s.vault.renounceRole(
            s.vault.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.vault.renounceRole(s.vault.OPERATOR(), deployParams.deployer);

        s.defaultBondStrategy.renounceRole(
            s.defaultBondStrategy.ADMIN_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.renounceRole(
            s.defaultBondStrategy.ADMIN_DELEGATE_ROLE(),
            deployParams.deployer
        );
        s.defaultBondStrategy.renounceRole(
            s.defaultBondStrategy.OPERATOR(),
            deployParams.deployer
        );
        s.validator.revokeRole(
            deployParams.deployer,
            DeployConstants.ADMIN_ROLE_BIT
        );

        return (deployParams, s);
    }
}
