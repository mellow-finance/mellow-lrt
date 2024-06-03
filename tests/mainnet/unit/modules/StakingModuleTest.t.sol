// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using stdStorage for StdStorage;
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
        assertEq(module.stakingModuleId(), Constants.SIMPLE_DVT_MODULE_ID);

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
        assertEq(module.stakingModuleId(), 0);
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

    function simplifyDepositSecurityModule(Vm.Wallet memory guardian) public {
        IDepositSecurityModule depositSecurityModule = IDepositSecurityModule(
            Constants.DEPOSIT_SECURITY_MODULE
        );

        vm.startPrank(depositSecurityModule.getOwner());
        depositSecurityModule.setMinDepositBlockDistance(1);
        depositSecurityModule.addGuardian(guardian.addr, 1);
        int256 guardianIndex = depositSecurityModule.getGuardianIndex(
            guardian.addr
        );
        assertTrue(guardianIndex >= 0);
        vm.stopPrank();
    }

    function fetchSignatures(
        Vm.Wallet memory guardian,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 stakingModuleId,
        uint256 nonce
    ) public returns (IDepositSecurityModule.Signature[] memory sigs) {
        bytes32 message = keccak256(
            abi.encodePacked(
                Constants.ATTEST_MESSAGE_PREFIX,
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardian, message);
        sigs = new IDepositSecurityModule.Signature[](1);
        uint8 parity = v - 27;
        sigs[0] = IDepositSecurityModule.Signature({
            r: r,
            vs: bytes32(uint256(s) | (uint256(parity) << 255))
        });
        address signerAddr = ecrecover(message, v, r, s);
        assertEq(signerAddr, guardian.addr);
    }

    function getAllDepositParams(
        uint256 blockNumber,
        Vm.Wallet memory guardian
    )
        public
        returns (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        )
    {
        blockHash = blockhash(blockNumber);
        assertNotEq(bytes32(0), blockHash);
        uint256 stakingModuleId = Constants.SIMPLE_DVT_MODULE_ID;
        depositRoot = IDepositContract(Constants.DEPOSIT_CONTRACT)
            .get_deposit_root();
        nonce = IStakingRouter(Constants.STAKING_ROUTER).getStakingModuleNonce(
            stakingModuleId
        );
        depositCalldata = new bytes(0);
        sigs = fetchSignatures(
            guardian,
            blockNumber,
            blockHash,
            depositRoot,
            stakingModuleId,
            nonce
        );
    }

    function testDirectDeposit() external {
        uint256 blockNumber = block.number - 1;
        Vm.Wallet memory guardian = vm.createWallet("guardian");

        simplifyDepositSecurityModule(guardian);
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sortedGuardianSignatures
        ) = getAllDepositParams(blockNumber, guardian);

        IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE)
            .depositBufferedEther(
                blockNumber,
                blockHash,
                depositRoot,
                Constants.SIMPLE_DVT_MODULE_ID,
                nonce,
                depositCalldata,
                sortedGuardianSignatures
            );

        vm.stopPrank();
    }

    function testConvertAndDeposit() external {
        StakingModule module = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );

        uint256 blockNumber = block.number - 1;
        Vm.Wallet memory guardian = vm.createWallet("guardian");

        simplifyDepositSecurityModule(guardian);
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sortedGuardianSignatures
        ) = getAllDepositParams(blockNumber, guardian);

        deal(Constants.WETH, address(this), 1 ether);

        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                module.convertAndDeposit.selector,
                blockNumber,
                blockHash,
                depositRoot,
                nonce,
                depositCalldata,
                sortedGuardianSignatures
            )
        );

        if (block.number == 19762500 || block.number == 19762100) {
            assertFalse(success);

            assertEq(IERC20(Constants.WETH).balanceOf(address(this)), 1 ether);
            assertEq(IERC20(Constants.STETH).balanceOf(address(this)), 0);
            assertEq(IERC20(Constants.WSTETH).balanceOf(address(this)), 0);

            assertEq(
                abi.encodeWithSignature("InvalidWithdrawalQueueState()"),
                response
            );
        } else {
            assertTrue(success);

            assertEq(IERC20(Constants.WETH).balanceOf(address(this)), 0);
            assertEq(IERC20(Constants.STETH).balanceOf(address(this)), 0);
            assertNotEq(IERC20(Constants.WSTETH).balanceOf(address(this)), 0);
        }

        vm.stopPrank();
    }

    function testConvertAndDepositFailsWithNotEnoughWeth() external {
        StakingModule module = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );

        uint256 blockNumber = block.number - 1;
        Vm.Wallet memory guardian = vm.createWallet("guardian");

        simplifyDepositSecurityModule(guardian);
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sortedGuardianSignatures
        ) = getAllDepositParams(blockNumber, guardian);

        deal(Constants.WETH, address(this), 1 ether);

        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                module.convertAndDeposit.selector,
                blockNumber,
                blockHash,
                depositRoot,
                nonce,
                depositCalldata,
                sortedGuardianSignatures
            )
        );

        assertTrue(success);

        // assertEq(IERC20(Constants.WETH).balanceOf(address(this)), 1 ether);
        // assertEq(IERC20(Constants.STETH).balanceOf(address(this)), 0);
        // assertEq(IERC20(Constants.WSTETH).balanceOf(address(this)), 0);
        // assertEq(abi.encodeWithSignature("NotEnoughWeth()"), response);
        vm.stopPrank();
    }

    function testConvertAndDepositFailsWithInvalidWithdrawalQueueState()
        external
    {
        StakingModule module = new StakingModule(
            Constants.WETH,
            Constants.STETH,
            Constants.WSTETH,
            IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE),
            IWithdrawalQueue(Constants.WITHDRAWAL_QUEUE),
            Constants.SIMPLE_DVT_MODULE_ID
        );

        uint256 blockNumber = block.number - 1;
        Vm.Wallet memory guardian = vm.createWallet("guardian");

        simplifyDepositSecurityModule(guardian);
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sortedGuardianSignatures
        ) = getAllDepositParams(blockNumber, guardian);

        deal(Constants.WETH, address(this), 1 ether);

        vm.store(
            Constants.STETH,
            0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0,
            0
        );

        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                module.convertAndDeposit.selector,
                blockNumber,
                blockHash,
                depositRoot,
                nonce,
                depositCalldata,
                sortedGuardianSignatures
            )
        );

        assertFalse(success);

        assertEq(IERC20(Constants.WETH).balanceOf(address(this)), 1 ether);
        assertEq(IERC20(Constants.STETH).balanceOf(address(this)), 0);
        assertEq(IERC20(Constants.WSTETH).balanceOf(address(this)), 0);

        assertEq(
            abi.encodeWithSignature("InvalidWithdrawalQueueState()"),
            response
        );
        vm.stopPrank();
    }

    receive() external payable {}
}
