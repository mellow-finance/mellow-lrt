// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
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

    function fetchSignatures(
        Vm.Wallet memory guardian,
        bytes32 ATTEST_MESSAGE_PREFIX,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 stakingModuleId,
        uint256 nonce
    ) public returns (IDepositSecurityModule.Signature[] memory sigs) {
        bytes32 message = keccak256(
            abi.encodePacked(
                ATTEST_MESSAGE_PREFIX,
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce
            )
        );
        assertEq(
            message,
            0x96453aa2f20f60fddcdd2d60d20bd4ea4ee48e6a9406c2afb2152f155ca6902f
        );
        {
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
    }

    function testDirectDeposit() external {
        deal(Constants.WETH, address(this), 544 ether);

        uint256 blockNumber = block.number - 1;
        bytes32 ATTEST_MESSAGE_PREFIX = 0xd85557c963041ae93cfa5927261eeb189c486b6d293ccee7da72ca9387cc241d;
        uint256 nonce;
        bytes32 depositRoot;

        Vm.Wallet memory guardian = vm.createWallet("guardian");
        uint256 stakingModuleId = Constants.SIMPLE_DVT_MODULE_ID;

        bytes32 blockHash;
        {
            (
                ,
                bytes memory response
            ) = 0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696.call(
                    abi.encodeWithSignature(
                        "getBlockHash(uint256)",
                        blockNumber
                    )
                );
            blockHash = abi.decode(response, (bytes32));
        }
        assertNotEq(bytes32(0), blockHash);

        {
            (, bytes memory response) = address(
                0x00000000219ab540356cBB839Cbe05303d7705Fa
            ).call(abi.encodeWithSignature("get_deposit_root()"));
            depositRoot = abi.decode(response, (bytes32));
        }
        {
            (, bytes memory response) = address(
                0xFdDf38947aFB03C621C71b06C9C70bce73f12999
            ).call(
                    abi.encodeWithSignature(
                        "getStakingModuleNonce(uint256)",
                        stakingModuleId
                    )
                );
            nonce = abi.decode(response, (uint256));
        }

        {
            vm.startPrank(0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c);
            Constants.DEPOSIT_SECURITY_MODULE.call(
                abi.encodeWithSignature(
                    "setMinDepositBlockDistance(uint256)",
                    1
                )
            );
            (bool success, ) = Constants.DEPOSIT_SECURITY_MODULE.call(
                abi.encodeWithSignature(
                    "addGuardian(address,uint256)",
                    guardian.addr,
                    1
                )
            );
            assertTrue(success);

            (, bytes memory response) = Constants.DEPOSIT_SECURITY_MODULE.call(
                abi.encodeWithSignature(
                    "getGuardianIndex(address)",
                    guardian.addr
                )
            );
            int256 guardianIndex = abi.decode(response, (int256));
            console2.log("Guardian index:", guardianIndex);
            assertTrue(guardianIndex >= 0);
            vm.stopPrank();
        }

        bytes memory depositCalldata = new bytes(0);
        IDepositSecurityModule.Signature[]
            memory sortedGuardianSignatures = fetchSignatures(
                guardian,
                ATTEST_MESSAGE_PREFIX,
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce
            );

        IDepositSecurityModule(Constants.DEPOSIT_SECURITY_MODULE)
            .depositBufferedEther(
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce,
                depositCalldata,
                sortedGuardianSignatures
            );

        vm.stopPrank();
    }

    receive() external payable {}
}
