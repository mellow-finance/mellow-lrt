// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        ChainlinkOracle oracle = new ChainlinkOracle();
        assertNotEq(address(oracle), address(0));
        assertEq(oracle.MAX_ORACLE_AGE(), 2 days);
        assertEq(oracle.Q96(), 2 ** 96);
    }

    function setBaseToken() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address baseToken = Constants.WSTETH;
        assertEq(oracle.baseTokens(address(vault)), address(0));

        vm.prank(admin);
        oracle.setBaseToken(address(vault), baseToken);

        assertEq(oracle.baseTokens(address(vault)), baseToken);
    }

    function setBaseTokenFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address baseToken = Constants.WSTETH;
        assertEq(oracle.baseTokens(address(vault)), address(0));

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracle.setBaseToken(address(vault), baseToken);
    }

    function setChainlinkOracles() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](2);
        oracles[0] = Constants.STETH_CHAINLINK_ORACLE;
        oracles[1] = Constants.RETH_CHAINLINK_ORACLE;

        assertEq(oracle.aggregatorsV3(address(vault), tokens[0]), address(0));
        assertEq(oracle.aggregatorsV3(address(vault), tokens[1]), address(0));

        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, oracles);

        assertEq(oracle.aggregatorsV3(address(vault), tokens[0]), oracles[0]);
        assertEq(oracle.aggregatorsV3(address(vault), tokens[1]), oracles[1]);
    }

    function setChainlinkOraclesEmpty() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        address[] memory tokens = new address[](0);

        address[] memory oracles = new address[](0);
        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, oracles);
    }

    function setChainlinkOraclesFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](0),
            new address[](0)
        );
    }

    function setChainlinkOraclesFailsWithForbidden2() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](1),
            new address[](1)
        );
    }

    function setChainlinkOraclesFailsWithInvalidLength() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](1);

        vm.startPrank(admin);

        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        oracle.setChainlinkOracles(address(vault), tokens, oracles);

        vm.stopPrank();
    }

    function testGetPrice() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.STETH;
        address[] memory aggregators = new address[](1);
        aggregators[0] = Constants.STETH_CHAINLINK_ORACLE;
        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, aggregators);
        (uint256 price, uint8 decimals) = oracle.getPrice(
            address(vault),
            tokens[0]
        );
        if (block.number == 19762100) {
            assertEq(price, 999823159305817100);
        }
        assertApproxEqAbs(price, 1 ether, 0.0002 ether);

        assertEq(decimals, 18);
    }

    function testGetPriceFailsWithAddressZero() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.STETH;
        address[] memory aggregators = new address[](1);
        aggregators[0] = Constants.STETH_CHAINLINK_ORACLE;
        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, aggregators);

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.getPrice(address(vault), Constants.WETH);
    }

    function testGetPriceFailsWithStaleOracle() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.STETH;
        address[] memory aggregators = new address[](1);
        aggregators[0] = address(new ChainlinkOracleMock());
        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, aggregators);

        vm.expectRevert(abi.encodeWithSignature("StaleOracle()"));
        oracle.getPrice(address(vault), tokens[0]);
    }

    function testPriceX96() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](2);
        oracles[0] = Constants.STETH_CHAINLINK_ORACLE;
        oracles[1] = Constants.RETH_CHAINLINK_ORACLE;

        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, oracles);

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.STETH);

        assertEq(oracle.priceX96(address(vault), Constants.STETH), 2 ** 96);

        {
            uint256 priceX96 = oracle.priceX96(address(vault), Constants.RETH);
            // 1 reth ~= 1.1 steth
            // so if base == steth then priceX96(reth) ~= 1.1 * 2^96
            uint256 expectedPriceX96 = uint256(11 * 2 ** 96) / 10;
            if (block.number != 19762100)
                assertEq(priceX96, 87578452645126174255746518636);
            assertApproxEqAbs(
                priceX96,
                expectedPriceX96,
                uint256(2 ** 96) / 100
            );
        }
    }

    function testPriceX96FailsWithStaleOracle1() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](2);
        oracles[0] = address(new ChainlinkOracleMock());
        oracles[1] = Constants.RETH_CHAINLINK_ORACLE;

        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, oracles);

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.STETH);

        assertEq(oracle.priceX96(address(vault), Constants.STETH), 2 ** 96);

        vm.expectRevert(abi.encodeWithSignature("StaleOracle()"));
        oracle.priceX96(address(vault), Constants.RETH);
    }

    function testPriceX96FailsWithStaleOracle2() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](2);
        oracles[0] = Constants.STETH_CHAINLINK_ORACLE;
        oracles[1] = address(new ChainlinkOracleMock());

        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, oracles);

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.STETH);

        assertEq(oracle.priceX96(address(vault), Constants.STETH), 2 ** 96);

        vm.expectRevert(abi.encodeWithSignature("StaleOracle()"));
        oracle.priceX96(address(vault), Constants.RETH);
    }

    function testPriceX96FailsWithAddressZero() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(vault), Constants.WETH);
    }

    function testPriceX96ForSameToken() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.STETH);

        assertEq(2 ** 96, oracle.priceX96(address(vault), Constants.STETH));
    }

    function testPriceX96ForZeroTokenFailsWithAddressZero() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.STETH);

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(vault), address(0));
    }

    function testSetBaseTokenFailsForZeroVault() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        vm.expectRevert();
        oracle.setBaseToken(address(0), Constants.STETH);
    }
}
