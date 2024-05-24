// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        assertNotEq(address(module), address(0));
    }

    function testDelegateCall() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address admin = address(this);
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        (bool success, bytes memory response) = address(module).delegatecall(
            abi.encodeWithSelector(
                IDefaultBondTvlModule.setParams.selector,
                address(vault),
                new address[](0)
            )
        );

        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("Forbidden()"));

        (success, response) = address(module).delegatecall(
            abi.encodeWithSelector(ITvlModule.tvl.selector, address(vault))
        );

        assertFalse(success);
        assertEq(response, abi.encodeWithSignature("Forbidden()"));

        vm.stopPrank();
    }

    function testSetParamsEmptyArray() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address[] memory bonds = new address[](0);
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        module.setParams(address(vault), bonds);
        vm.stopPrank();

        bytes memory vaultParams = module.vaultParams(address(vault));
        assertNotEq(vaultParams.length, 0);
        assertEq(keccak256(vaultParams), keccak256(abi.encode(bonds)));
    }

    function testSetParamsSingleBond() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        module.setParams(address(vault), bonds);
        vm.stopPrank();

        bytes memory vaultParams = module.vaultParams(address(vault));
        assertEq(vaultParams.length, 0x60);
        assertEq(keccak256(vaultParams), keccak256(abi.encode(bonds)));
    }

    function testSetParamsMultipleBonds() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address[] memory bonds = new address[](2);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));
        bonds[1] = address(new DefaultBondMock(Constants.USDC));
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        module.setParams(address(vault), bonds);
        vm.stopPrank();

        bytes memory vaultParams = module.vaultParams(address(vault));
        assertEq(vaultParams.length, 0x80);
        assertEq(keccak256(vaultParams), keccak256(abi.encode(bonds)));
    }

    function testTvlEmptyParams() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 0);
    }

    function testTvlSingleBond() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        module.setParams(address(vault), bonds);
        vm.stopPrank();

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 1);
        assertEq(data[0].token, address(bonds[0]));
        assertEq(data[0].underlyingToken, Constants.WSTETH);
        assertEq(data[0].amount, 0);
        assertEq(data[0].underlyingAmount, 0);
    }

    function testTvlMultipleBonds() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address[] memory bonds = new address[](2);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));
        bonds[1] = address(new DefaultBondMock(Constants.USDC));
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        module.setParams(address(vault), bonds);
        vm.stopPrank();

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 2);
        assertEq(data[0].token, address(bonds[0]));
        assertEq(data[0].underlyingToken, Constants.WSTETH);
        assertEq(data[0].amount, 0);
        assertEq(data[0].underlyingAmount, 0);
        assertEq(data[1].token, address(bonds[1]));
        assertEq(data[1].underlyingToken, Constants.USDC);
        assertEq(data[1].amount, 0);
        assertEq(data[1].underlyingAmount, 0);
    }

    function testTvlMultipleBondsNonZeroAmounts() external {
        DefaultBondTvlModule module = new DefaultBondTvlModule();
        address[] memory bonds = new address[](2);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));
        bonds[1] = address(new DefaultBondMock(Constants.USDC));
        address admin = address(bytes20(keccak256("vault-admin")));
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        module.setParams(address(vault), bonds);
        vm.stopPrank();

        uint256 wstethAmount = 1;
        uint256 usdcAmount = 2;
        deal(address(bonds[0]), address(vault), wstethAmount);
        deal(address(bonds[1]), address(vault), usdcAmount);

        ITvlModule.Data[] memory data = module.tvl(address(vault));
        assertEq(data.length, 2);
        assertEq(data[0].token, address(bonds[0]));
        assertEq(data[0].underlyingToken, Constants.WSTETH);
        assertEq(data[0].amount, wstethAmount);
        assertEq(data[0].underlyingAmount, wstethAmount);
        assertEq(data[1].token, address(bonds[1]));
        assertEq(data[1].underlyingToken, Constants.USDC);
        assertEq(data[1].amount, usdcAmount);
        assertEq(data[1].underlyingAmount, usdcAmount);
    }
}
