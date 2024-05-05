// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testContructor() external {
        ManagedTvlModule module = new ManagedTvlModule();
        assertNotEq(address(module), address(0));
    }

    function testTvlEmpty() external {
        ManagedTvlModule module = new ManagedTvlModule();
        VaultMock vault = new VaultMock(address(this));
        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 0);
        assertEq(module.vaultParams(address(vault)), new bytes(0));
    }

    function testSetParamsPermissions() external {
        ManagedTvlModule module = new ManagedTvlModule();
        address admin = address(1);
        address attacker = address(2);

        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);
        module.setParams(address(vault), new ITvlModule.Data[](0));
        vm.stopPrank();

        vm.startPrank(attacker);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        module.setParams(address(vault), new ITvlModule.Data[](0));
        vm.stopPrank();
    }

    function testTvlDelegateCall() external {
        ManagedTvlModule module = new ManagedTvlModule();
        VaultMock vault = new VaultMock(address(this));
        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSignature("tvl(address)", address(vault))
        );
        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("Forbidden()"));
    }

    function testSetParamsDelegateCall() external {
        ManagedTvlModule module = new ManagedTvlModule();
        address admin = address(1);
        vm.startPrank(admin);
        VaultMock vault = new VaultMock(admin);

        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                ManagedTvlModule.setParams.selector,
                address(vault),
                new ITvlModule.Data[](0)
            )
        );
        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("Forbidden()"));

        vm.stopPrank();
    }

    function testTvlSingleToken() external {
        ManagedTvlModule module = new ManagedTvlModule();
        address admin = address(1);

        VaultMock vault = new VaultMock(admin);
        ITvlModule.Data[] memory setupData = new ITvlModule.Data[](1);
        setupData[0] = ITvlModule.Data({
            token: Constants.STETH,
            amount: 1 ether,
            underlyingToken: Constants.WETH,
            underlyingAmount: 1 ether,
            isDebt: false
        });

        {
            ITvlModule.Data[] memory response = module.tvl(address(vault));

            assertEq(
                keccak256(abi.encode(new ITvlModule.Data[](0))),
                keccak256(abi.encode(response))
            );
        }

        vm.prank(admin);
        module.setParams(address(vault), setupData);

        {
            ITvlModule.Data[] memory response = module.tvl(address(vault));

            assertEq(
                keccak256(abi.encode(setupData)),
                keccak256(abi.encode(response))
            );
        }

        {
            bytes memory data = module.vaultParams(address(vault));
            assertEq(keccak256(abi.encode(setupData)), keccak256(data));
        }
    }

    function testTvlMultipleTokens() external {
        ManagedTvlModule module = new ManagedTvlModule();
        address admin = address(1);

        VaultMock vault = new VaultMock(admin);
        ITvlModule.Data[] memory setupData = new ITvlModule.Data[](2);
        setupData[0] = ITvlModule.Data({
            token: Constants.STETH,
            amount: 1 ether,
            underlyingToken: Constants.WETH,
            underlyingAmount: 1 ether,
            isDebt: false
        });

        setupData[1] = ITvlModule.Data({
            token: Constants.USDC,
            amount: 10 gwei,
            underlyingToken: Constants.USDC,
            underlyingAmount: 10 gwei,
            isDebt: true
        });

        {
            ITvlModule.Data[] memory response = module.tvl(address(vault));

            assertEq(
                keccak256(abi.encode(new ITvlModule.Data[](0))),
                keccak256(abi.encode(response))
            );
        }

        vm.prank(admin);
        module.setParams(address(vault), setupData);

        {
            ITvlModule.Data[] memory response = module.tvl(address(vault));

            assertEq(
                keccak256(abi.encode(setupData)),
                keccak256(abi.encode(response))
            );
        }

        {
            bytes memory data = module.vaultParams(address(vault));
            assertEq(keccak256(abi.encode(setupData)), keccak256(data));
        }
    }
}
