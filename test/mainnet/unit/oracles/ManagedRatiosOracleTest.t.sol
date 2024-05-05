// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        ManagedRatiosOracle oracle = new ManagedRatiosOracle();
        assertNotEq(address(oracle), address(0));
        assertEq(oracle.Q96(), 2 ** 96);
    }

    function testUpdateRatios() external {
        ManagedRatiosOracle oracle = new ManagedRatiosOracle();
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.WETH;
        vault.setUnderlyingTokens(tokens);

        uint128[] memory ratios = new uint128[](2);
        ratios[0] = 2 ** 96 / 2;
        ratios[1] = 2 ** 96 / 2;
        vm.startPrank(admin);
        oracle.updateRatios(address(vault), ratios);
        vm.stopPrank();
        uint128[] memory result = oracle.getTargetRatiosX96(address(vault));
        assertEq(result[0], 2 ** 96 / 2);
        assertEq(result[1], 2 ** 96 / 2);
    }

    function testUpdateRatiosFailsWithForbidden() external {
        ManagedRatiosOracle oracle = new ManagedRatiosOracle();
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.WETH;
        vault.setUnderlyingTokens(tokens);
        uint128[] memory ratios = new uint128[](2);
        ratios[0] = 2 ** 96 / 2;
        ratios[1] = 2 ** 96 / 2;
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracle.updateRatios(address(vault), ratios);
        vm.stopPrank();
    }

    function testUpdateRatiosFailsWithInvalidLength() external {
        ManagedRatiosOracle oracle = new ManagedRatiosOracle();
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.WETH;
        vault.setUnderlyingTokens(tokens);
        uint128[] memory ratios = new uint128[](2);
        ratios[0] = 2 ** 96 / 2;
        ratios[1] = 2 ** 96 / 2;
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        oracle.updateRatios(address(vault), new uint128[](0));
        vm.stopPrank();
    }

    function testUpdateRatiosFailsWithInvalidCumulativeRatio() external {
        ManagedRatiosOracle oracle = new ManagedRatiosOracle();
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.WETH;

        vault.setUnderlyingTokens(tokens);
        uint128[] memory ratios = new uint128[](2);
        ratios[0] = 2 ** 96 / 2;
        ratios[1] = 2 ** 96 / 2 - 1;
        vm.startPrank(admin);

        vm.expectRevert(abi.encodeWithSignature("InvalidCumulativeRatio()"));
        oracle.updateRatios(address(vault), ratios);
        vm.stopPrank();
    }

    function testGetTargetRatiosX96() external {
        ManagedRatiosOracle oracle = new ManagedRatiosOracle();
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.WSTETH;
        tokens[1] = Constants.WETH;

        vault.setUnderlyingTokens(tokens);
        uint128[] memory ratios = new uint128[](2);
        ratios[0] = 2 ** 96 / 2;
        ratios[1] = 2 ** 96 / 2;

        {
            vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
            oracle.getTargetRatiosX96(address(vault));
        }

        vm.prank(admin);
        oracle.updateRatios(address(vault), ratios);
        {
            uint128[] memory result = oracle.getTargetRatiosX96(address(vault));
            assertEq(
                keccak256(abi.encode(ratios)),
                keccak256(abi.encode(result))
            );
        }

        vault.setUnderlyingTokens(new address[](0));
        {
            vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
            oracle.getTargetRatiosX96(address(vault));
        }
    }
}
