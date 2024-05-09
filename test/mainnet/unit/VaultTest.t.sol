// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    address public immutable admin =
        address(bytes20(keccak256("mellow-vault-admin")));

    address public immutable operator =
        address(bytes20(keccak256("mellow-vault-operator")));

    function testConstructor() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vault.requireAdmin(admin);
        assertEq(vault.name(), "Mellow LRT Vault");
        assertEq(vault.symbol(), "mLRT");
        assertEq(vault.decimals(), 18);
        assertNotEq(address(vault.configurator()), address(0));
    }

    function testAddTokenInRandomOrder() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        address[] memory underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 0);

        vm.prank(admin);
        vault.addToken(Constants.WETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 1);
        assertEq(underlyingTokens[0], Constants.WETH); // [WETH]

        vm.prank(admin);
        vault.addToken(Constants.WSTETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 2);
        assertEq(underlyingTokens[0], Constants.WSTETH); // [WSTETH, WETH]

        vm.prank(admin);
        vault.addToken(Constants.STETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 3);
        assertEq(underlyingTokens[1], Constants.STETH); // [WSTETH, STETH, WETH]

        vm.prank(admin);
        vault.addToken(Constants.USDT);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 4);
        assertEq(underlyingTokens[3], Constants.USDT); // [WSTETH, STETH, WETH, USDT]

        vm.prank(admin);
        vault.addToken(Constants.RETH);

        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 5);
        assertEq(underlyingTokens[1], Constants.RETH); // [WSTETH, RETH, STETH, WETH, USDT]

        address[5] memory targetArray = [
            Constants.WSTETH,
            Constants.RETH,
            Constants.STETH,
            Constants.WETH,
            Constants.USDT
        ];

        for (uint256 i = 0; i < underlyingTokens.length; i++) {
            assertEq(underlyingTokens[i], targetArray[i]);
            if (i > 0) {
                assertTrue(underlyingTokens[i] > underlyingTokens[i - 1]);
            }
        }
    }

    function testAddTokenInSortedOrder() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        address[] memory underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 0);

        address[5] memory tokens = [
            Constants.WSTETH,
            Constants.RETH,
            Constants.STETH,
            Constants.WETH,
            Constants.USDT
        ];
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(admin);
            vault.addToken(tokens[i]);

            underlyingTokens = vault.underlyingTokens();
            assertEq(underlyingTokens.length, i + 1);
            for (uint256 j = 0; j <= i; j++) {
                assertEq(underlyingTokens[j], tokens[j]);
                if (j > 0) {
                    assertTrue(underlyingTokens[j] > underlyingTokens[j - 1]);
                }
            }
        }
    }

    function testAddTokenInReversedSortedOrder() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        address[] memory underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 0);

        address[5] memory tokens = [
            Constants.WSTETH,
            Constants.RETH,
            Constants.STETH,
            Constants.WETH,
            Constants.USDT
        ];
        uint256 n = 5;
        for (uint256 i = 0; i < n; i++) {
            vm.prank(admin);
            vault.addToken(tokens[n - 1 - i]);

            underlyingTokens = vault.underlyingTokens();
            assertEq(underlyingTokens.length, i + 1);
            for (uint256 j = 0; j <= i; j++) {
                assertEq(underlyingTokens[j], tokens[j + (n - 1 - i)]);
                if (j > 0) {
                    assertTrue(underlyingTokens[j] > underlyingTokens[j - 1]);
                }
            }
        }
    }

    function testAddTokenFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.addToken(address(0));
    }

    function testAddTokenFailsWithInvalidToken() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        vault.addToken(address(0));
        vault.addToken(address(1));
        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        vault.addToken(address(1));
        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        vault.addToken(address(vault));
        vm.stopPrank();
    }

    function testRemoveToken() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);

        vault.addToken(Constants.WETH);
        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.RETH);

        address[] memory underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 3);
        assertEq(underlyingTokens[0], Constants.WSTETH);
        assertEq(underlyingTokens[1], Constants.RETH);
        assertEq(underlyingTokens[2], Constants.WETH);

        vault.removeToken(Constants.WETH);
        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 2);
        assertEq(underlyingTokens[0], Constants.WSTETH);
        assertEq(underlyingTokens[1], Constants.RETH);

        vault.removeToken(Constants.WSTETH);
        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 1);
        assertEq(underlyingTokens[0], Constants.RETH);

        vault.removeToken(Constants.RETH);
        underlyingTokens = vault.underlyingTokens();
        assertEq(underlyingTokens.length, 0);

        vm.stopPrank();
    }

    function testRemoveTokenFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.removeToken(address(0));
    }

    function testRemoveTokenFailsWithInvalidToken() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);

        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        vault.removeToken(address(0));

        vm.stopPrank();
    }

    function testRemoveTokenFailsWithNonZeroValue() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);

        ERC20TvlModule tvlModule = new ERC20TvlModule();
        vault.addTvlModule(address(tvlModule));
        vault.addToken(Constants.WETH);
        deal(Constants.WETH, address(vault), 1 ether);

        vm.expectRevert(abi.encodeWithSignature("NonZeroValue()"));
        vault.removeToken(Constants.WETH);

        vm.stopPrank();
    }

    function testAddTvlModule() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);

        ERC20TvlModule tvlModule = new ERC20TvlModule();

        address[] memory tvlModules = vault.tvlModules();
        assertEq(tvlModules.length, 0);

        vault.addTvlModule(address(tvlModule));

        tvlModules = vault.tvlModules();
        assertEq(tvlModules.length, 1);
        assertEq(tvlModules[0], address(tvlModule));

        vm.stopPrank();
    }

    function testAddTvlModuleFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule tvlModule = new ERC20TvlModule();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.addTvlModule(address(tvlModule));
    }

    function testAddTvlModuleFailsWithInvalidToken() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);
        DefaultBondTvlModule tvlModule = new DefaultBondTvlModule();
        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));
        tvlModule.setParams(address(vault), bonds);

        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        vault.addTvlModule(address(tvlModule));

        vm.stopPrank();
    }

    function testRemoveTvlModule() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);
        DefaultBondTvlModule tvlModule = new DefaultBondTvlModule();
        vault.addTvlModule(address(tvlModule));
        address[] memory tvlModules = vault.tvlModules();
        assertEq(tvlModules.length, 1);
        assertEq(tvlModules[0], address(tvlModule));

        vault.removeTvlModule(address(tvlModule));
        tvlModules = vault.tvlModules();
        assertEq(tvlModules.length, 0);

        vm.stopPrank();
    }

    function testRemoveTvlModuleFailWithInvalidState() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidState()"));
        vault.removeTvlModule(address(0));
        vm.stopPrank();
    }

    function testRemoveTvlModuleFailWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.removeTvlModule(address(0));
    }

    function testExternalCall() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);

        ManagedValidator validator = new ManagedValidator(admin);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        configurator.stageValidator(address(validator));
        configurator.commitValidator();

        uint8 externalCallRole = 1;
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        // operator -> vault
        validator.grantRole(operator, externalCallRole);
        validator.grantContractRole(address(vault), externalCallRole);

        // vault -> router
        validator.grantRole(address(vault), externalCallRole);
        validator.grantContractRole(address(uniswapV3Router), externalCallRole);

        vm.stopPrank();
        vm.startPrank(operator);

        (bool success, bytes memory response) = vault.externalCall(
            uniswapV3Router,
            abi.encodeWithSignature("WETH9()")
        );

        assertTrue(success);
        address weth = abi.decode(response, (address));
        assertEq(weth, Constants.WETH);

        vm.stopPrank();
    }

    function testExternalCallFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.externalCall(uniswapV3Router, abi.encodeWithSignature("WETH9()"));

        vm.startPrank(admin);
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        configurator.stageDelegateModuleApproval(uniswapV3Router);
        configurator.commitDelegateModuleApproval(uniswapV3Router);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.externalCall(uniswapV3Router, abi.encodeWithSignature("WETH9()"));

        vm.stopPrank();
    }

    function testDelegateCall() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);

        ManagedValidator validator = new ManagedValidator(admin);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );

        uint8 delegateCallRole = 1;
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        configurator.stageDelegateModuleApproval(uniswapV3Router);
        configurator.commitDelegateModuleApproval(uniswapV3Router);

        configurator.stageValidator(address(validator));
        configurator.commitValidator();

        // operator -> vault
        validator.grantRole(operator, delegateCallRole);
        validator.grantContractRole(address(vault), delegateCallRole);

        // vault -> router
        validator.grantRole(address(vault), delegateCallRole);
        validator.grantContractRole(address(uniswapV3Router), delegateCallRole);

        vm.stopPrank();
        vm.startPrank(operator);

        (bool success, bytes memory response) = vault.delegateCall(
            uniswapV3Router,
            abi.encodeWithSignature("WETH9()")
        );

        assertTrue(success);
        address weth = abi.decode(response, (address));
        assertEq(weth, Constants.WETH);

        vm.stopPrank();
    }

    function testDelegateCallFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        address uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.delegateCall(uniswapV3Router, abi.encodeWithSignature("WETH9()"));

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.delegateCall(uniswapV3Router, abi.encodeWithSignature("WETH9()"));
        vm.stopPrank();
    }

    function testUnderlyingTvl() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);

        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondTvlModule defaultBondTvlModule = new DefaultBondTvlModule();
        ManagedTvlModule managedTvlModule = new ManagedTvlModule();

        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));

        defaultBondTvlModule.setParams(address(vault), bonds);

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);
        vault.addToken(Constants.RETH);

        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(defaultBondTvlModule));
        vault.addTvlModule(address(managedTvlModule));

        // zero tvl
        (address[] memory tokens, uint256[] memory amounts) = vault
            .underlyingTvl();
        assertEq(tokens.length, 3);
        assertEq(amounts.length, 3);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);

        // positive tvls
        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.RETH, address(vault), 10 ether);
        deal(Constants.WETH, address(vault), 100 ether);
        deal(bonds[0], address(vault), 1000 ether);

        (tokens, amounts) = vault.underlyingTvl();
        assertEq(tokens.length, 3);
        assertEq(amounts.length, 3);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], Constants.WETH);

        assertEq(amounts[0], 1001 ether);
        assertEq(amounts[1], 10 ether);
        assertEq(amounts[2], 100 ether);

        // debt included tvl
        ITvlModule.Data[] memory data = new ITvlModule.Data[](3);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 1001 ether,
            underlyingAmount: 1001 ether - 1 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether,
            underlyingAmount: 10 ether - 1 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether,
            underlyingAmount: 100 ether - 1 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.underlyingTvl();

        assertEq(tokens.length, 3);
        assertEq(amounts.length, 3);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 1 ether);
        assertEq(amounts[2], 1 ether);

        // zero tvl due to debt

        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 1001 ether,
            underlyingAmount: 1001 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.underlyingTvl();

        assertEq(tokens.length, 3);
        assertEq(amounts.length, 3);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);

        vm.stopPrank();
    }

    function testUnderlyingTvlFailsWithInvalidStateDueToHighDebt() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);

        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondTvlModule defaultBondTvlModule = new DefaultBondTvlModule();
        ManagedTvlModule managedTvlModule = new ManagedTvlModule();

        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));

        defaultBondTvlModule.setParams(address(vault), bonds);

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);
        vault.addToken(Constants.RETH);

        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(defaultBondTvlModule));
        vault.addTvlModule(address(managedTvlModule));

        // zero tvl
        (address[] memory tokens, uint256[] memory amounts) = vault
            .underlyingTvl();
        assertEq(tokens.length, 3);
        assertEq(amounts.length, 3);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);

        // positive tvls
        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.RETH, address(vault), 10 ether);
        deal(Constants.WETH, address(vault), 100 ether);
        deal(bonds[0], address(vault), 1000 ether);

        (tokens, amounts) = vault.underlyingTvl();
        assertEq(tokens.length, 3);
        assertEq(amounts.length, 3);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], Constants.WETH);

        assertEq(amounts[0], 1001 ether);
        assertEq(amounts[1], 10 ether);
        assertEq(amounts[2], 100 ether);

        // debt > tvl
        ITvlModule.Data[] memory data = new ITvlModule.Data[](3);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 1001 ether,
            underlyingAmount: 1001 ether + 1 wei,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        vm.expectRevert(abi.encodeWithSignature("InvalidState()"));
        vault.underlyingTvl();

        vm.stopPrank();
    }

    function testBaseTvl() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);

        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondTvlModule defaultBondTvlModule = new DefaultBondTvlModule();
        ManagedTvlModule managedTvlModule = new ManagedTvlModule();

        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));

        defaultBondTvlModule.setParams(address(vault), bonds);

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);
        vault.addToken(Constants.RETH);

        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(defaultBondTvlModule));
        vault.addTvlModule(address(managedTvlModule));

        // zero tvl
        (address[] memory tokens, uint256[] memory amounts) = vault.baseTvl();
        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);
        assertEq(amounts[3], 0);

        // positive tvls
        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.RETH, address(vault), 10 ether);
        deal(Constants.WETH, address(vault), 100 ether);
        deal(bonds[0], address(vault), 1000 ether);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);

        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 10 ether);
        assertEq(amounts[2], 1000 ether);
        assertEq(amounts[3], 100 ether);

        // debt included tvl
        ITvlModule.Data[] memory data = new ITvlModule.Data[](3);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 0 ether,
            underlyingAmount: 0 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether - 1 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether - 1 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 1 ether);
        assertEq(amounts[2], 1000 ether);
        assertEq(amounts[3], 1 ether);

        // zero tvl due to debt
        data = new ITvlModule.Data[](4);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 1 ether,
            underlyingAmount: 1 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        data[3] = ITvlModule.Data({
            token: bonds[0],
            underlyingToken: Constants.WSTETH,
            amount: 1000 ether,
            underlyingAmount: 1000 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);
        assertEq(amounts[3], 0);

        vm.stopPrank();
    }

    function testBaseTvlReversedOrder() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);

        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondTvlModule defaultBondTvlModule = new DefaultBondTvlModule();
        ManagedTvlModule managedTvlModule = new ManagedTvlModule();

        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));

        defaultBondTvlModule.setParams(address(vault), bonds);

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);
        vault.addToken(Constants.RETH);

        vault.addTvlModule(address(defaultBondTvlModule));
        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(managedTvlModule));

        // zero tvl
        (address[] memory tokens, uint256[] memory amounts) = vault.baseTvl();
        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);
        assertEq(amounts[3], 0);

        // positive tvls
        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.RETH, address(vault), 10 ether);
        deal(Constants.WETH, address(vault), 100 ether);
        deal(bonds[0], address(vault), 1000 ether);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);

        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 10 ether);
        assertEq(amounts[2], 1000 ether);
        assertEq(amounts[3], 100 ether);

        // debt included tvl
        ITvlModule.Data[] memory data = new ITvlModule.Data[](3);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 0 ether,
            underlyingAmount: 0 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether - 1 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether - 1 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 1 ether);
        assertEq(amounts[2], 1000 ether);
        assertEq(amounts[3], 1 ether);

        // zero tvl due to debt
        data = new ITvlModule.Data[](4);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 1 ether,
            underlyingAmount: 1 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        data[3] = ITvlModule.Data({
            token: bonds[0],
            underlyingToken: Constants.WSTETH,
            amount: 1000 ether,
            underlyingAmount: 1000 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);
        assertEq(amounts[3], 0);

        vm.stopPrank();
    }

    function testBaseTvlFailsWithInvalidStateDueToHighDebt() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);

        vm.startPrank(admin);

        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondTvlModule defaultBondTvlModule = new DefaultBondTvlModule();
        ManagedTvlModule managedTvlModule = new ManagedTvlModule();

        address[] memory bonds = new address[](1);
        bonds[0] = address(new DefaultBondMock(Constants.WSTETH));

        defaultBondTvlModule.setParams(address(vault), bonds);

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.WETH);
        vault.addToken(Constants.RETH);

        vault.addTvlModule(address(erc20TvlModule));
        vault.addTvlModule(address(defaultBondTvlModule));
        vault.addTvlModule(address(managedTvlModule));

        // zero tvl
        (address[] memory tokens, uint256[] memory amounts) = vault.baseTvl();
        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
        assertEq(amounts[2], 0);
        assertEq(amounts[3], 0);

        // positive tvls
        deal(Constants.WSTETH, address(vault), 1 ether);
        deal(Constants.RETH, address(vault), 10 ether);
        deal(Constants.WETH, address(vault), 100 ether);
        deal(bonds[0], address(vault), 1000 ether);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);

        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 10 ether);
        assertEq(amounts[2], 1000 ether);
        assertEq(amounts[3], 100 ether);

        // debt included tvl
        ITvlModule.Data[] memory data = new ITvlModule.Data[](3);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 0 ether,
            underlyingAmount: 0 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether - 1 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether - 1 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        (tokens, amounts) = vault.baseTvl();

        assertEq(tokens.length, 4);
        assertEq(amounts.length, 4);
        assertEq(tokens[0], Constants.WSTETH);
        assertEq(tokens[1], Constants.RETH);
        assertEq(tokens[2], bonds[0]);
        assertEq(tokens[3], Constants.WETH);

        assertEq(amounts[0], 1 ether);
        assertEq(amounts[1], 1 ether);
        assertEq(amounts[2], 1000 ether);
        assertEq(amounts[3], 1 ether);

        // zero tvl due to debt
        data = new ITvlModule.Data[](4);
        data[0] = ITvlModule.Data({
            token: Constants.WSTETH,
            underlyingToken: Constants.WSTETH,
            amount: 1 ether,
            underlyingAmount: 1 ether,
            isDebt: true
        });

        data[1] = ITvlModule.Data({
            token: Constants.RETH,
            underlyingToken: Constants.RETH,
            amount: 10 ether,
            underlyingAmount: 10 ether,
            isDebt: true
        });

        data[2] = ITvlModule.Data({
            token: Constants.WETH,
            underlyingToken: Constants.WETH,
            amount: 100 ether,
            underlyingAmount: 100 ether,
            isDebt: true
        });

        data[3] = ITvlModule.Data({
            token: bonds[0],
            underlyingToken: Constants.WSTETH,
            amount: 1001 ether, // overflow
            underlyingAmount: 1000 ether,
            isDebt: true
        });

        managedTvlModule.setParams(address(vault), data);

        vm.expectRevert(abi.encodeWithSignature("InvalidState()"));
        vault.baseTvl();

        vm.stopPrank();
    }

    function _setUp(Vault vault) private {
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        vault.addTvlModule(address(erc20TvlModule));

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.RETH);
        vault.addToken(Constants.WETH);
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );

        // oracles setup
        {
            ManagedRatiosOracle ratiosOracle = new ManagedRatiosOracle();

            uint128[] memory ratiosX96 = new uint128[](3);
            ratiosX96[0] = 2 ** 96;
            ratiosOracle.updateRatios(address(vault), true, ratiosX96);
            ratiosOracle.updateRatios(address(vault), false, ratiosX96);

            configurator.stageRatiosOracle(address(ratiosOracle));
            configurator.commitRatiosOracle();

            ChainlinkOracle chainlinkOracle = new ChainlinkOracle();
            chainlinkOracle.setBaseToken(address(vault), Constants.WSTETH);
            address[] memory tokens = new address[](3);
            tokens[0] = Constants.WSTETH;
            tokens[1] = Constants.RETH;
            tokens[2] = Constants.WETH;

            address[] memory oracles = new address[](3);
            oracles[0] = address(
                new AggregatorV3WstethMock(
                    Constants.WSTETH,
                    IAggregatorV3(Constants.STETH_CHAINLINK_ORACLE)
                )
            );
            oracles[1] = Constants.RETH_CHAINLINK_ORACLE;
            oracles[2] = address(new AggregatorV3WethMock());

            chainlinkOracle.setChainlinkOracles(
                address(vault),
                tokens,
                oracles
            );

            configurator.stagePriceOracle(address(chainlinkOracle));
            configurator.commitPriceOracle();
        }

        configurator.stageMaximalTotalSupply(1000 ether);
        configurator.commitMaximalTotalSupply();
    }

    function _initialDeposit(Vault vault) private {
        vm.startPrank(operator);

        deal(Constants.WSTETH, operator, 10 gwei);
        deal(Constants.RETH, operator, 0 ether);
        deal(Constants.WETH, operator, 0 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), 10 gwei);
        // IERC20(Constants.RETH).safeIncreaseAllowance(address(vault), 0);
        // IERC20(Constants.WETH).safeIncreaseAllowance(address(vault), 0);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 gwei;
        vault.deposit(address(vault), amounts, 10 gwei, type(uint256).max);

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 10 gwei);
        assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);
        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(operator), 0);

        vm.stopPrank();
    }

    function testDepositInitial() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);
    }

    function testDepositInitialFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 gwei;

        deal(Constants.WSTETH, address(this), 10 gwei);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), 10 gwei);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.deposit(address(vault), amounts, 10 gwei, type(uint256).max);

        vm.startPrank(operator);

        deal(Constants.WSTETH, operator, 10 gwei);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), 10 gwei);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.deposit(address(this), amounts, 10 gwei, type(uint256).max);

        vm.stopPrank();
    }

    function testDepositInitialFailsWithValueZero() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();

        deal(Constants.WSTETH, operator, 10 gwei);
        deal(Constants.RETH, operator, 0 ether);
        deal(Constants.WETH, operator, 0 ether);

        vm.startPrank(operator);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), 10 gwei);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 gwei;
        vm.expectRevert(abi.encodeWithSignature("ValueZero()"));
        vault.deposit(address(vault), amounts, 0, type(uint256).max);
        vm.stopPrank();
    }

    function testDepositRegular() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
        assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);
        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(depositor), 10 ether);
        vm.stopPrank();
    }

    function testDepositRegularWithDepositCallback() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        vm.startPrank(admin);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );

        DepositCallbackMock callback = new DepositCallbackMock();

        configurator.stageDepositCallback(address(callback));
        configurator.commitDepositCallback();

        vm.stopPrank();

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;

        assertFalse(callback.flag());
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
        assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
        assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);
        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(depositor), 10 ether);

        assertTrue(callback.flag());

        vm.stopPrank();
    }

    function testDepositRegularFailsWithLimitOverflow() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10000 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10000 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10000 ether;

        vm.expectRevert(abi.encodeWithSignature("LimitOverflow()"));
        vault.deposit(depositor, amounts, 10000 ether, type(uint256).max);
        vm.stopPrank();
    }

    function testDepositRegularFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(operator);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        configurator.stageDepositsLock();
        configurator.commitDepositsLock();

        vm.stopPrank();

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.stopPrank();
    }

    function testDepositRegularFailsWithValueZero() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 0 wei;

        vm.expectRevert(abi.encodeWithSignature("ValueZero()"));
        vault.deposit(depositor, amounts, 0 wei, type(uint256).max);

        vm.stopPrank();
    }

    function testDepositMultipleRegular() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        uint256 lpAmount = 0;
        uint256 wstethBalance = 10 gwei;

        for (uint256 i = 0; i < 5; i++) {
            deal(Constants.WSTETH, depositor, 10 ether);
            IERC20(Constants.WSTETH).safeIncreaseAllowance(
                address(vault),
                10 ether
            );

            uint256[] memory amounts = new uint256[](3);
            amounts[0] = 10 ether;

            vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
            assertEq(
                IERC20(Constants.WSTETH).balanceOf(address(vault)),
                wstethBalance + 10 ether
            );
            wstethBalance += 10 ether;
            assertEq(IERC20(Constants.RETH).balanceOf(address(vault)), 0);
            assertEq(IERC20(Constants.WETH).balanceOf(address(vault)), 0);

            assertEq(vault.balanceOf(address(vault)), 10 gwei);
            assertEq(vault.balanceOf(depositor), lpAmount + 10 ether);
            lpAmount += 10 ether;
        }
        vm.stopPrank();
    }

    function testDepositRegularFailsWithAddressZero() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        vault.deposit(address(0), amounts, 10 ether, type(uint256).max);
        vm.stopPrank();
    }

    function testDepositRegularFailsWithInsufficientLpAmount() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;

        vm.expectRevert(abi.encodeWithSignature("InsufficientLpAmount()"));
        vault.deposit(
            address(depositor),
            amounts,
            10000 ether,
            type(uint256).max
        );
        vm.stopPrank();
    }

    function testDepositRegularFailsWithInvalidLength() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));

        vm.startPrank(depositor);

        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 ether;

        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.stopPrank();
    }

    function testDepositRegularFailsWithDeadline() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);
        vm.expectRevert(abi.encodeWithSignature("Deadline()"));
        vault.deposit(
            address(this),
            new uint256[](3),
            10 gwei,
            block.timestamp - 1
        );
    }

    function testRegisterWithdrawal() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );

        assertEq(vault.balanceOf(depositor), 0);
        IVault.WithdrawalRequest memory request = vault.withdrawalRequest(
            depositor
        );
        assertEq(request.lpAmount, 10 ether);
        assertEq(request.to, depositor);
        assertEq(request.deadline, type(uint256).max);
        assertEq(request.timestamp, block.timestamp);
        assertEq(
            request.tokensHash,
            keccak256(abi.encode(vault.underlyingTokens()))
        );
        // assertEq(request.minAmounts, new uint256[](3));

        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            true
        );

        assertEq(vault.balanceOf(depositor), 0);
        assertEq(request.lpAmount, 10 ether);
        assertEq(request.to, depositor);
        assertEq(request.deadline, type(uint256).max);
        assertEq(request.timestamp, block.timestamp);
        assertEq(
            request.tokensHash,
            keccak256(abi.encode(vault.underlyingTokens()))
        );

        vault.registerWithdrawal(
            depositor,
            20 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            true
        );

        assertEq(vault.balanceOf(depositor), 0);
        assertEq(request.lpAmount, 10 ether);
        assertEq(request.to, depositor);
        assertEq(request.deadline, type(uint256).max);
        assertEq(request.timestamp, block.timestamp);
        assertEq(
            request.tokensHash,
            keccak256(abi.encode(vault.underlyingTokens()))
        );

        vm.stopPrank();
    }

    function testRegisterWithdrawalFailsWithDeadline() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.expectRevert(abi.encodeWithSignature("Deadline()"));
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            0,
            type(uint256).max,
            true
        );

        vm.expectRevert(abi.encodeWithSignature("Deadline()"));
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            0,
            true
        );

        vm.expectRevert(abi.encodeWithSignature("Deadline()"));
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            block.timestamp - 1,
            type(uint256).max,
            true
        );

        vm.expectRevert(abi.encodeWithSignature("Deadline()"));
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            block.timestamp - 1,
            0,
            true
        );

        vm.stopPrank();
    }

    function testRegisterWithdrawalFailsWithInvalidState() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            true
        );

        vm.expectRevert(abi.encodeWithSignature("InvalidState()"));
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();
    }

    function testRegisterWithdrawalFailsWithValueZero() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.expectRevert(abi.encodeWithSignature("ValueZero()"));
        vault.registerWithdrawal(
            depositor,
            0,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();
    }

    function testRegisterWithdrawalFailsWithAddressZero() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        vault.registerWithdrawal(
            address(0),
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();
    }

    function testRegisterWithdrawalFailsWithInvalidLength() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](2),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();
    }

    function testCancelWithdrawalRequest() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 1);
            assertEq(withdrawers[0], depositor);
        }

        vault.cancelWithdrawalRequest();

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
        }

        IVault.WithdrawalRequest memory request = vault.withdrawalRequest(
            depositor
        );

        assertEq(request.lpAmount, 0);
        assertEq(vault.balanceOf(depositor), 10 ether);
        vm.stopPrank();

        vm.startPrank(address(0));
        // no revert
        vault.cancelWithdrawalRequest();
        vm.stopPrank();
    }

    function testAnalyzeRequest() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        minAmounts[0] = type(uint256).max;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertFalse(isProcessingPossible);
        assertFalse(isWithdrawalPossible);

        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            block.timestamp,
            block.timestamp,
            true
        );

        (isProcessingPossible, isWithdrawalPossible, ) = vault.analyzeRequest(
            vault.calculateStack(),
            vault.withdrawalRequest(depositor)
        );
        assertTrue(isProcessingPossible);
        assertTrue(isWithdrawalPossible);

        skip(1);
        (isProcessingPossible, isWithdrawalPossible, ) = vault.analyzeRequest(
            vault.calculateStack(),
            vault.withdrawalRequest(depositor)
        );
        assertFalse(isProcessingPossible);
        assertFalse(isWithdrawalPossible);

        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            block.timestamp,
            block.timestamp,
            true
        );

        (isProcessingPossible, isWithdrawalPossible, ) = vault.analyzeRequest(
            vault.calculateStack(),
            vault.withdrawalRequest(depositor)
        );
        assertTrue(isProcessingPossible);
        assertTrue(isWithdrawalPossible);

        deal(Constants.WSTETH, address(vault), 5 ether);
        deal(Constants.RETH, address(vault), 5 ether);

        (isProcessingPossible, isWithdrawalPossible, ) = vault.analyzeRequest(
            vault.calculateStack(),
            vault.withdrawalRequest(depositor)
        );
        assertTrue(isProcessingPossible);
        assertFalse(isWithdrawalPossible);

        vm.stopPrank();
    }

    function testProcessWithdrawals() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = amounts;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertTrue(isWithdrawalPossible);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 1);
            assertEq(withdrawers[0], depositor);
        }
        vm.startPrank(operator);
        address[] memory users = new address[](1);
        users[0] = depositor;
        vault.processWithdrawals(users);
        vm.stopPrank();

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
        }
    }

    function testProcessWithdrawalsWithWithdrawalCallback() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = amounts;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertTrue(isWithdrawalPossible);

        WithdrawalCallbackMock callback = new WithdrawalCallbackMock();
        vm.startPrank(admin);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        configurator.stageWithdrawalCallback(address(callback));
        configurator.commitWithdrawalCallback();

        vm.stopPrank();

        vm.startPrank(operator);
        address[] memory users = new address[](1);
        users[0] = depositor;
        assertFalse(callback.flag());
        bool[] memory success = vault.processWithdrawals(users);
        assertTrue(callback.flag());
        assertEq(success.length, 1);
        assertTrue(success[0]);
        vm.stopPrank();
    }

    function testProcessWithdrawalsClosesDueToIsProcessingPossible() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        minAmounts[0] = type(uint256).max;
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertFalse(isProcessingPossible);
        assertFalse(isWithdrawalPossible);

        vm.startPrank(operator);
        address[] memory users = new address[](1);
        users[0] = depositor;
        bool[] memory success = vault.processWithdrawals(users);
        assertEq(success.length, 1);
        assertFalse(success[0]);

        IVault.WithdrawalRequest memory request = vault.withdrawalRequest(
            depositor
        );
        assertEq(request.lpAmount, 0);
        assertEq(vault.balanceOf(depositor), 10 ether);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
        }

        vm.stopPrank();
    }

    function testProcessWithdrawalsIgnoresDueToIsWithdrawalPossible() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        deal(Constants.WSTETH, address(vault), 5 ether);
        deal(Constants.RETH, address(vault), 5 ether);

        (bool isProcessingPossible, bool isWithdrawalPossible, ) = vault
            .analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(depositor)
            );
        assertTrue(isProcessingPossible);
        assertFalse(isWithdrawalPossible);

        vm.startPrank(operator);
        address[] memory users = new address[](1);
        users[0] = depositor;
        bool[] memory success = vault.processWithdrawals(users);
        assertEq(success.length, 1);
        assertFalse(success[0]);

        IVault.WithdrawalRequest memory request = vault.withdrawalRequest(
            depositor
        );
        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 1);
            assertEq(withdrawers[0], depositor);
        }
        assertEq(request.lpAmount, 10 ether);
        assertEq(vault.balanceOf(depositor), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawFailsWithDeadline() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.expectRevert(abi.encodeWithSignature("Deadline()"));
        vault.emergencyWithdraw(new uint256[](0), 0);
    }

    function testEmergencyWithdraw() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            type(uint256).max,
            type(uint256).max,
            false
        );

        vault.emergencyWithdraw(new uint256[](3), type(uint256).max);

        IVault.WithdrawalRequest memory request = vault.withdrawalRequest(
            depositor
        );
        assertEq(request.lpAmount, 0);

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 10 gwei);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(depositor)),
            10 ether
        );

        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(address(depositor)), 0);
        vm.stopPrank();
    }

    function testEmergencyWithdrawCancelsRequestDueToDeadline() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            block.timestamp,
            block.timestamp,
            false
        );

        skip(1);

        vault.emergencyWithdraw(new uint256[](3), type(uint256).max);

        IVault.WithdrawalRequest memory request = vault.withdrawalRequest(
            depositor
        );
        assertEq(request.lpAmount, 0);

        {
            address[] memory withdrawers = vault.pendingWithdrawers();
            assertEq(withdrawers.length, 0);
        }

        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
        assertEq(IERC20(Constants.WSTETH).balanceOf(address(depositor)), 0);

        assertEq(vault.balanceOf(address(vault)), 10 gwei);
        assertEq(vault.balanceOf(address(depositor)), 10 ether);

        vm.stopPrank();
    }

    function testEmergencyWithdrawFailsWithInvalidState() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.expectRevert(abi.encodeWithSignature("InvalidState()"));
        vault.emergencyWithdraw(new uint256[](3), type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            block.timestamp,
            block.timestamp,
            false
        );

        vm.stopPrank();
        vm.startPrank(admin);

        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        configurator.stageEmergencyWithdrawalDelay(1);
        configurator.commitEmergencyWithdrawalDelay();

        vm.stopPrank();
        vm.startPrank(depositor);

        vm.expectRevert(abi.encodeWithSignature("InvalidState()"));
        vault.emergencyWithdraw(new uint256[](3), type(uint256).max);

        vm.stopPrank();
    }

    function testEmergencyWithdrawFailsWithInvalidLength() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            block.timestamp,
            block.timestamp,
            false
        );
        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        vault.emergencyWithdraw(new uint256[](2), type(uint256).max);

        vm.stopPrank();
    }

    function testEmergencyWithdrawFailsWithInsufficientAmount() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        vm.startPrank(admin);
        vault.grantRole(vault.ADMIN_DELEGATE_ROLE(), admin);
        vault.grantRole(vault.OPERATOR(), operator);
        _setUp(vault);
        vm.stopPrank();
        _initialDeposit(vault);

        address depositor = address(bytes20(keccak256("depositor")));
        vm.startPrank(depositor);
        deal(Constants.WSTETH, depositor, 10 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(
            address(vault),
            10 ether
        );
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 ether;
        uint256[] memory minAmounts = new uint256[](3);
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            minAmounts,
            block.timestamp,
            block.timestamp,
            false
        );

        minAmounts = new uint256[](3);
        minAmounts[0] = 100 ether;
        vm.expectRevert(abi.encodeWithSignature("InsufficientAmount()"));
        vault.emergencyWithdraw(minAmounts, type(uint256).max);

        vm.stopPrank();
    }
}
