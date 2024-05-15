// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        StakingModule module = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );
        assertEq(module.weth(), Constants.WETH);
        assertEq(module.steth(), Constants.STETH);
        assertEq(module.wsteth(), Constants.WSTETH);
        assertEq(
            address(module.depositSecurityModule()),
            Constants.DEPOSIT_SECURITY_MODULE
        );
        assertEq(address(module.withdrawalQueue()), Constants.WITHDRAWAL_QUEUE);
        assertEq(module.simpleDVTModuleId(), Constants.SIMPLE_DVT_MODULE_ID);

        module = new StakingModule(
            address(0),
            address(0),
            address(0),
            IDepositSecurityModule(address(0)),
            IWithdrawalQueue(address(0)),
            0
        );
        assertEq(module.weth(), address(0));
        assertEq(module.steth(), address(0));
        assertEq(module.wsteth(), address(0));
        assertEq(address(module.depositSecurityModule()), address(0));
        assertEq(address(module.withdrawalQueue()), address(0));
        assertEq(module.simpleDVTModuleId(), 0);
    }

    function testExternalCall() external {
        StakingModule module = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        module.convert(1 ether);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        module.convertAndDeposit(
            0,
            0,
            bytes32(0),
            bytes32(0),
            0,
            new bytes(0),
            new IDepositSecurityModule.Signature[](0)
        );
    }

    function testConvert() external {
        StakingModule module = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );

        deal(Constants.WETH, address(this), 1 ether);
        (bool success, ) = address(module).delegatecall(
            abi.encodeWithSelector(module.convert.selector, 1 ether)
        );

        assertTrue(success);

        assertEq(IERC20(Constants.WETH).balanceOf(address(this)), 0);
        assertEq(IERC20(Constants.STETH).balanceOf(address(this)), 0);
        assertNotEq(IERC20(Constants.WSTETH).balanceOf(address(this)), 0);
    }

    receive() external payable {}
}
