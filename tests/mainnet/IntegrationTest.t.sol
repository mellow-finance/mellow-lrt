// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./Fixture.sol";

contract Integration is Fixture {
    using SafeERC20 for IERC20;
    address public constant uniswapSwapRouter =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    function _initializeVault() private {
        vm.startPrank(Constants.VAULT_ADMIN);
        configurator.stageMaximalTotalSupply(type(uint256).max);
        configurator.commitMaximalTotalSupply();
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));
        configurator.stageDelegateModuleApproval(address(erc20SwapModule));
        configurator.commitDelegateModuleApproval(address(erc20SwapModule));
        configurator.stageRatiosOracle(address(ratiosOracle));
        configurator.commitRatiosOracle();
        configurator.stagePriceOracle(address(oracle));
        configurator.commitPriceOracle();
        configurator.stageValidator(address(validator));
        configurator.commitValidator();
        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        validator.grantRole(address(vault), Constants.DEFAULT_BOND_ROLE);
        validator.grantRole(address(vault), Constants.SWAP_ROUTER_ROLE);
        validator.grantContractRole(
            address(vault),
            Constants.BOND_STRATEGY_ROLE
        );
        validator.grantContractRole(
            address(bondModule),
            Constants.DEFAULT_BOND_ROLE
        );
        validator.grantContractRole(
            address(erc20SwapModule),
            Constants.SWAP_ROUTER_ROLE
        );
        validator.setCustomValidator(
            address(bondModule),
            address(customValidator)
        );
        validator.setCustomValidator(
            address(erc20SwapModule),
            address(erc20SwapValidator)
        );
        customValidator.setSupportedBond(address(wstethDefaultBond), true);
        erc20SwapValidator.setSupportedRouter(uniswapSwapRouter, true);
        erc20SwapValidator.setSupportedToken(Constants.WSTETH, true);
        erc20SwapValidator.setSupportedToken(Constants.WETH, true);
        newPrank(Constants.VAULT_ADMIN);
        uint128[] memory ratiosX96 = new uint128[](1);
        ratiosX96[0] = uint128(Q96);
        vault.addToken(Constants.WSTETH);
        oracle.setBaseToken(address(vault), Constants.WSTETH);
        ratiosOracle.updateRatios(address(vault), true, ratiosX96);
        ratiosOracle.updateRatios(address(vault), false, ratiosX96);
        vault.addTvlModule(address(erc20TvlModule));
        address[] memory bonds = new address[](1);
        bonds[0] = address(wstethDefaultBond);
        bondTvlModule.setParams(address(vault), bonds);
        vault.addTvlModule(address(bondTvlModule));
        newPrank(address(this));
        mintWsteth(address(this), 10 ether);
        mintWsteth(Constants.DEPOSITOR, 10 ether);
    }

    function _setupDepositPermissions(IVault vault) private {
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        uint8 depositRole = 14;
        IManagedValidator validator = IManagedValidator(
            configurator.validator()
        );
        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        if (address(validator) == address(0)) {
            validator = new ManagedValidator(Constants.VAULT_ADMIN);
            configurator.stageValidator(address(validator));
            configurator.commitValidator();
        }
        validator.grantPublicRole(depositRole);
        validator.grantContractSignatureRole(
            address(vault),
            IVault.deposit.selector,
            depositRole
        );
        newPrank(Constants.VAULT_ADMIN);
    }

    function _initialDeposit() private {
        uint256 amount = 10 gwei;
        IERC20(Constants.WSTETH).safeTransfer(Constants.VAULT_ADMIN, amount);
        newPrank(Constants.VAULT_ADMIN);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), amount);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        _setupDepositPermissions(vault);
        vault.deposit(address(vault), amounts, amount, type(uint256).max, 0);
    }

    function testPrimitiveOperations() external {
        _initializeVault();
        _initialDeposit();
        newPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 10 ether;
            IERC20(Constants.WSTETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max,
                0
            );
        }
        console2.log(
            "Depositor balances before:",
            vault.balanceOf(Constants.DEPOSITOR),
            IERC20(Constants.WSTETH).balanceOf(Constants.DEPOSITOR)
        );
        vault.registerWithdrawal(
            Constants.DEPOSITOR,
            vault.balanceOf(Constants.DEPOSITOR) / 2,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
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
            IERC20(Constants.WSTETH).balanceOf(Constants.DEPOSITOR)
        );
        newPrank(Constants.VAULT_ADMIN);
        vm.expectRevert(abi.encodeWithSignature("NonZeroValue()"));
        vault.removeToken(Constants.WSTETH);
        vm.stopPrank();
    }

    function testDepositCallback() external {
        _initializeVault();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            Constants.PROTOCOL_GOVERNANCE_ADMIN,
            vault,
            erc20TvlModule,
            bondModule
        );
        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        validator.grantRole(address(strategy), Constants.BOND_STRATEGY_ROLE);
        newPrank(Constants.VAULT_ADMIN);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        vault.grantRole(vault.OPERATOR(), address(strategy));
        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0] = IDefaultBondStrategy.Data({
                bond: address(wstethDefaultBond),
                ratioX96: Q96
            });
            strategy.setData(Constants.WSTETH, data);
        }
        newPrank(Constants.VAULT_ADMIN);
        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();
        newPrank(address(this));
        _initialDeposit();
        // normal deposit
        newPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 10 ether;
            IERC20(Constants.WSTETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max,
                0
            );
        }
        console2.log(
            "Depositor balances before:",
            vault.balanceOf(Constants.DEPOSITOR),
            IERC20(Constants.WSTETH).balanceOf(Constants.DEPOSITOR)
        );
        vault.registerWithdrawal(
            Constants.DEPOSITOR,
            vault.balanceOf(Constants.DEPOSITOR) / 2,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
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
            IERC20(Constants.WSTETH).balanceOf(Constants.DEPOSITOR)
        );
        vm.stopPrank();
        // assert(false);
    }
    function testERC20SwapModule() external {
        _initializeVault();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            Constants.PROTOCOL_GOVERNANCE_ADMIN,
            vault,
            erc20TvlModule,
            bondModule
        );
        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        validator.grantRole(address(strategy), Constants.BOND_STRATEGY_ROLE);
        validator.grantRole(
            Constants.VAULT_ADMIN,
            Constants.BOND_STRATEGY_ROLE
        );
        newPrank(Constants.VAULT_ADMIN);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), Constants.VAULT_ADMIN);
        vault.grantRole(vault.OPERATOR(), address(strategy));
        newPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        {
            IDefaultBondStrategy.Data[]
                memory data = new IDefaultBondStrategy.Data[](1);
            data[0] = IDefaultBondStrategy.Data({
                bond: address(wstethDefaultBond),
                ratioX96: Q96
            });
            strategy.setData(Constants.WSTETH, data);
        }
        newPrank(Constants.VAULT_ADMIN);
        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();
        newPrank(address(this));
        _initialDeposit();
        // normal deposit
        newPrank(Constants.DEPOSITOR);
        {
            uint256 amount = 10 ether;
            IERC20(Constants.WSTETH).safeIncreaseAllowance(
                address(vault),
                amount
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            vault.deposit(
                Constants.DEPOSITOR,
                amounts,
                amount,
                type(uint256).max,
                0
            );
        }
        console2.log(
            vault.balanceOf(Constants.DEPOSITOR),
            IERC20(Constants.WSTETH).balanceOf(address(vault))
        );
        newPrank(Constants.VAULT_ADMIN);
        vault.delegateCall(
            address(bondModule),
            abi.encodeWithSelector(
                DefaultBondModule.withdraw.selector,
                wstethDefaultBond,
                wstethDefaultBond.balanceOf(address(vault))
            )
        );
        {
            vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
            vault.delegateCall(
                address(erc20SwapModule),
                abi.encodeWithSelector(
                    IERC20SwapModule.swap.selector,
                    IERC20SwapModule.SwapParams({
                        tokenIn: Constants.WSTETH,
                        tokenOut: Constants.WETH,
                        amountIn: 0.1 ether,
                        minAmountOut: 0.1 ether,
                        deadline: type(uint256).max
                    }),
                    uniswapSwapRouter,
                    abi.encodeWithSelector(
                        ISwapRouter.exactInputSingle.selector
                    )
                )
            );
        }
        {
            (bool success, ) = vault.delegateCall(
                address(erc20SwapModule),
                abi.encodeWithSelector(
                    IERC20SwapModule.swap.selector,
                    IERC20SwapModule.SwapParams({
                        tokenIn: Constants.WSTETH,
                        tokenOut: Constants.WETH,
                        amountIn: 0.1 ether,
                        minAmountOut: 0.1 ether,
                        deadline: type(uint256).max
                    }),
                    uniswapSwapRouter,
                    abi.encodeWithSelector(
                        ISwapRouter.exactInputSingle.selector,
                        ISwapRouter.ExactInputSingleParams({
                            tokenIn: Constants.WSTETH,
                            tokenOut: Constants.WETH,
                            fee: 100,
                            recipient: address(vault),
                            deadline: type(uint256).max,
                            amountIn: 0.1 ether,
                            amountOutMinimum: 0.1 ether,
                            sqrtPriceLimitX96: 0
                        })
                    )
                )
            );
            if (!success) {
                console2.log("Unsuccessful swap");
                assert(success);
            }
        }
        vm.stopPrank();
    }
    function testGovernance() external view {
        /*
        bytes32[] memory slots = configurator.viewSlots();
        for (uint256 i = 0; i < slots.length; i++) {
            console2.log(";\nbytes32 public constant DEFAULT_DELAY_SLOT =");
            console2.logBytes32(slots[i]);
        }
        */
        console2.log(configurator.baseDelay());
    }
}
