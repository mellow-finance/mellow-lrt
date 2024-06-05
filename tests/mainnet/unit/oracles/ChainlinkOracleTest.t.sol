// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    function testConstructor() external {
        ChainlinkOracle oracle = new ChainlinkOracle();
        assertNotEq(address(oracle), address(0));
        assertEq(oracle.Q96(), 2 ** 96);
    }

    function testSetBaseToken() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address baseToken = Constants.WSTETH;
        assertEq(oracle.baseTokens(address(vault)), address(0));

        vm.prank(admin);
        oracle.setBaseToken(address(vault), baseToken);

        assertEq(oracle.baseTokens(address(vault)), baseToken);

        vm.prank(admin);
        oracle.setBaseToken(address(vault), baseToken);

        assertEq(oracle.baseTokens(address(vault)), baseToken);
        vm.prank(admin);
        oracle.setBaseToken(address(vault), address(0));

        assertEq(oracle.baseTokens(address(vault)), address(0));
    }

    function testSetBaseTokenFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address baseToken = Constants.WSTETH;
        assertEq(oracle.baseTokens(address(vault)), address(0));

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracle.setBaseToken(address(vault), baseToken);
    }

    function testSetChainlinkOracles() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        IChainlinkOracle.AggregatorData[]
            memory data = new IChainlinkOracle.AggregatorData[](2);

        data[0] = IChainlinkOracle.AggregatorData({
            aggregatorV3: Constants.STETH_CHAINLINK_ORACLE,
            maxAge: 30 days
        });

        data[1] = IChainlinkOracle.AggregatorData({
            aggregatorV3: Constants.RETH_CHAINLINK_ORACLE,
            maxAge: 30 days
        });

        assertEq(
            oracle.aggregatorsData(address(vault), tokens[0]).aggregatorV3,
            address(0)
        );
        assertEq(
            oracle.aggregatorsData(address(vault), tokens[1]).aggregatorV3,
            address(0)
        );
        assertEq(oracle.aggregatorsData(address(vault), tokens[0]).maxAge, 0);
        assertEq(oracle.aggregatorsData(address(vault), tokens[1]).maxAge, 0);

        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, data);

        assertEq(
            oracle.aggregatorsData(address(vault), tokens[0]).aggregatorV3,
            data[0].aggregatorV3
        );
        assertEq(
            oracle.aggregatorsData(address(vault), tokens[1]).aggregatorV3,
            data[1].aggregatorV3
        );
        assertEq(
            oracle.aggregatorsData(address(vault), tokens[0]).maxAge,
            30 days
        );
        assertEq(
            oracle.aggregatorsData(address(vault), tokens[1]).maxAge,
            30 days
        );
    }

    function _convert(
        address[] memory aggregators
    ) private pure returns (IChainlinkOracle.AggregatorData[] memory data) {
        data = new IChainlinkOracle.AggregatorData[](aggregators.length);
        for (uint256 i = 0; i < aggregators.length; i++) {
            data[i] = IChainlinkOracle.AggregatorData({
                aggregatorV3: aggregators[i],
                maxAge: 30 days
            });
        }
    }

    function testSetChainlinkOraclesEmpty() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        address[] memory tokens = new address[](0);

        address[] memory oracles = new address[](0);
        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));
    }

    function testSetChainlinkOraclesFailsWithForbidden() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](0),
            _convert(new address[](0))
        );
    }

    function testSetChainlinkOraclesFailsWithInvalidLength() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](1),
            _convert(new address[](0))
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](0),
            _convert(new address[](1))
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](1),
            _convert(new address[](2))
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        oracle.setChainlinkOracles(
            address(vault),
            new address[](2),
            _convert(new address[](1))
        );

        oracle.setChainlinkOracles(
            address(vault),
            new address[](1),
            _convert(new address[](1))
        );
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
        oracle.setChainlinkOracles(
            address(vault),
            tokens,
            _convert(aggregators)
        );
        (uint256 price, uint8 decimals) = oracle.getPrice(
            address(vault),
            tokens[0]
        );
        if (block.number == 19762100) {
            assertEq(price, 999823159305817100);
        } else if (block.number == 19845261) {
            assertEq(price, 999600000000000400);
        }
        assertApproxEqAbs(price, 1 ether, 0.0005 ether);

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
        oracle.setChainlinkOracles(
            address(vault),
            tokens,
            _convert(aggregators)
        );

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
        vm.expectRevert(abi.encodeWithSignature("StaleOracle()"));
        oracle.setChainlinkOracles(
            address(vault),
            tokens,
            _convert(aggregators)
        );
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
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
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.STETH);

        assertEq(oracle.priceX96(address(vault), Constants.STETH), 2 ** 96);

        {
            uint256 priceX96 = oracle.priceX96(address(vault), Constants.RETH);
            // 1 reth ~= 1.1 steth
            // so if base == steth then priceX96(reth) ~= 1.1 * 2^96
            uint256 expectedPriceX96 = uint256(11 * 2 ** 96) / 10;
            if (block.number == 19845261)
                assertEq(priceX96, 87640277532012770051909751095);
            assertApproxEqAbs(
                priceX96,
                expectedPriceX96,
                uint256(2 ** 96) / 100
            );
        }
    }

    function testPriceX96StethUsdc() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH; // 18 decimals
        tokens[1] = Constants.USDC; // 8 decimals

        address[] memory oracles = new address[](2);
        oracles[0] = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8; // steth-usd oracle, 18 decimals
        oracles[1] = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6; // usdc-usd oracle, 8 decimals

        vm.prank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));

        vm.prank(admin);
        oracle.setBaseToken(address(vault), Constants.USDC);

        uint256 priceX96 = oracle.priceX96(address(vault), Constants.STETH);
        // 1 eth ~= 2917 usdc
        // expectedPriceX96 = 2917 * 1e-12 * 2**96
        uint256 expectedPriceX96 = uint256(2917 * 2 ** 96) / 1e12;
        if (block.number == 19845261) assertEq(priceX96, 231158100161120637905);
        assertApproxEqAbs(priceX96, expectedPriceX96, uint256(2 ** 96) / 100);
    }

    function testPriceX96FailsWithBaseStaleOracle() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](2);
        oracles[0] = address(new ChainlinkOracleMock());
        oracles[1] = Constants.RETH_CHAINLINK_ORACLE;

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("StaleOracle()"));
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));
        oracle.setBaseToken(address(vault), Constants.STETH);
        assertEq(oracle.priceX96(address(vault), Constants.STETH), 2 ** 96);
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(vault), Constants.RETH);
        vm.stopPrank();
    }

    function testPriceX96FailsWithRequestedStaleOracle() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](2);
        tokens[0] = Constants.STETH;
        tokens[1] = Constants.RETH;

        address[] memory oracles = new address[](2);
        oracles[0] = Constants.STETH_CHAINLINK_ORACLE;
        oracles[1] = address(new ChainlinkOracleMock());

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("StaleOracle()"));
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));

        oracle.setBaseToken(address(vault), Constants.STETH);

        assertEq(oracle.priceX96(address(vault), Constants.STETH), 2 ** 96);

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(vault), Constants.RETH);
        vm.stopPrank();
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

    function testPriceX96ForZeroBaseTokenFailsWithAddressZero() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(vault), Constants.STETH);
    }

    function testPriceX96ForZeroTokenFailsWithAddressZero() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(vault), address(0));
    }

    function testPriceX96ForZeroVaultFailsWithAddressZero() external {
        ChainlinkOracle oracle = new ChainlinkOracle();
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        oracle.priceX96(address(0), address(1));
    }

    function testSetBaseTokenFailsForZeroVault() external {
        ChainlinkOracle oracle = new ChainlinkOracle();
        vm.expectRevert();
        oracle.setBaseToken(address(0), Constants.STETH);
    }

    function testNegativeSignedAnswer() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.RETH;

        address[] memory oracles = new address[](1);
        AggregatorV3Mock aggregator = new AggregatorV3Mock();

        aggregator.setData(1, 1000000000000000000, 1, block.timestamp, 1);

        oracles[0] = address(aggregator);

        vm.startPrank(admin);
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));
        vm.stopPrank();

        aggregator.setData(1, -1000000000000000000, 1, block.timestamp, 1);

        vm.expectRevert(abi.encodeWithSignature("InvalidOracleData()"));
        oracle.getPrice(address(vault), tokens[0]);
    }

    function testResetOracle() external {
        address admin = address(bytes20(keccak256("vault-admin")));
        ChainlinkOracle oracle = new ChainlinkOracle();
        VaultMock vault = new VaultMock(admin);
        address[] memory tokens = new address[](1);
        tokens[0] = Constants.RETH;

        address[] memory oracles = new address[](1);
        AggregatorV3Mock aggregator = new AggregatorV3Mock();

        aggregator.setData(1, 1000000000000000000, 1, block.timestamp, 1);

        vm.startPrank(admin);
        oracles[0] = address(aggregator);
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));
        oracles[0] = address(1);
        vm.expectRevert();
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));
        oracles[0] = address(0);
        aggregator.setData(1, -1000000000000000000, 1, block.timestamp, 1);
        oracle.setChainlinkOracles(address(vault), tokens, _convert(oracles));
        vm.stopPrank();
    }
}
