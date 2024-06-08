// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../../scripts/mainnet/Deploy.s.sol";
import "../../../mainnet/mocks/DefaultBondMock.sol";

contract DefaultAccessControlTest is DeployScript, Validator, Test {
    using SafeERC20 for IERC20;

    address private constant admin = address(bytes20(keccak256("admin")));
    address private constant adminDelegate =
        address(bytes20(keccak256("admin delegate")));
    address private operator1;
    address private constant operator2 =
        address(bytes20(keccak256("operator2")));
    uint256 public constant Q96 = 2 ** 96;
    DeployInterfaces.DeployParameters deployParams;
    DeployInterfaces.DeploySetup setup;

    function setUp() public {
        bool test = true;
        string memory name = DeployConstants.STEAKHOUSE_VAULT_NAME;
        string memory symbol = DeployConstants.STEAKHOUSE_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_DEPLOYER;
        vm.startBroadcast(deployParams.deployer);

        deployParams.proxyAdmin = admin; // DeployConstants.MELLOW_LIDO_PROXY_MULTISIG;
        deployParams.admin = admin; //DeployConstants.MELLOW_LIDO_MULTISIG;

        // only for testing purposes
        if (test) {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY;
        } else {
            deployParams.wstethDefaultBond = DeployConstants
                .WSTETH_DEFAULT_BOND;
            deployParams.wstethDefaultBondFactory = DeployConstants
                .WSTETH_DEFAULT_BOND_FACTORY;
        }

        deployParams.wsteth = DeployConstants.WSTETH;
        deployParams.steth = DeployConstants.STETH;
        deployParams.weth = DeployConstants.WETH;

        deployParams.maximalTotalSupply = DeployConstants.MAXIMAL_TOTAL_SUPPLY;
        deployParams.initialDepositETH = DeployConstants.INITIAL_DEPOSIT_ETH;
        deployParams.firstDepositETH = DeployConstants.FIRST_DEPOSIT_ETH;
        deployParams = commonContractsDeploy(deployParams);
        deployParams.curator = operator1;
        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;

        (deployParams, setup) = deploy(deployParams);

        validateParameters(deployParams, setup, 0);
        if (false) {
            setup.depositWrapper.deposit{value: deployParams.firstDepositETH}(
                deployParams.deployer,
                address(0),
                deployParams.firstDepositETH,
                0,
                type(uint256).max
            );
        }
        vm.stopBroadcast();
        operator1 = address(setup.defaultBondStrategy);

        vm.startPrank(admin);
        setup.vault.grantRole(setup.vault.ADMIN_DELEGATE_ROLE(), adminDelegate);
        vm.stopPrank();

        vm.startPrank(adminDelegate);
        setup.vault.grantRole(setup.vault.OPERATOR(), operator2);
        vm.stopPrank();
    }

    function testFuzz_DefaultBondValidator(address randomAddress) public {
        vm.startPrank(admin);
        DefaultBondValidator defaultBondValidator = new DefaultBondValidator(
            admin
        );
        defaultBondValidator.setSupportedBond(address(0xdead), false);
        vm.stopPrank();

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        defaultBondValidator.setSupportedBond(address(0xdead), false);
        vm.stopPrank();

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        defaultBondValidator.setSupportedBond(address(0xdead), false);
        vm.stopPrank();

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        defaultBondValidator.setSupportedBond(address(0xdead), false);
        vm.stopPrank();
    }

    function testFuzz_ERC20SwapValidator(address randomAddress) public {
        vm.startPrank(admin);
        ERC20SwapValidator defaultBondValidator = new ERC20SwapValidator(admin);
        defaultBondValidator.setSupportedToken(address(0xdead), false);
        vm.stopPrank();

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        defaultBondValidator.setSupportedToken(address(0xdead), false);
        vm.stopPrank();

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        defaultBondValidator.setSupportedToken(address(0xdead), false);
        vm.stopPrank();

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        defaultBondValidator.setSupportedToken(address(0xdead), false);
        vm.stopPrank();
    }

    function testFuzz_VaultToken(
        address randomAddress,
        address randomToken
    ) public {
        vm.assume(randomToken != address(0));
        uint256 snapshotId = vm.snapshot();

        vm.startPrank(admin);
        setup.vault.addToken(randomToken);
        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        setup.vault.removeToken(DeployConstants.STETH);
        vm.stopPrank();
        vm.revertTo(snapshotId);

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.addToken(randomToken);
        vm.stopPrank();
        vm.revertTo(snapshotId);

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.addToken(randomToken);
        vm.stopPrank();
        vm.revertTo(snapshotId);

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.addToken(randomToken);
        vm.stopPrank();
        vm.revertTo(snapshotId);
    }

    function testFuzz_VaultTvlModule(address randomAddress) public {
        vm.assume(randomAddress != address(0));
        uint256 snapshotId0 = vm.snapshot();

        vm.startPrank(admin);
        setup.vault.removeTvlModule(address(deployParams.erc20TvlModule));
        uint256 snapshotId1 = vm.snapshot();
        setup.vault.addTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();
        vm.revertTo(snapshotId0);

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.removeTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();
        vm.revertTo(snapshotId0);

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.removeTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();
        vm.revertTo(snapshotId0);

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.removeTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();

        vm.revertTo(snapshotId1);

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.addTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();
        vm.revertTo(snapshotId1);

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.addTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();
        vm.revertTo(snapshotId1);

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.addTvlModule(address(deployParams.erc20TvlModule));
        vm.stopPrank();
    }

    function testFuzz_VaultProcessWithdrawals(address randomAddress) public {
        vm.assume(randomAddress != address(0));
        address[] memory users = new address[](1);
        users[0] = vm.createWallet("user").addr;
        uint256 amount = 1 ether;

        vm.deal(users[0], amount);

        vm.startPrank(users[0]);
        setup.depositWrapper.deposit{value: amount}(
            users[0],
            address(0),
            amount,
            0,
            type(uint256).max
        );

        setup.vault.registerWithdrawal(
            users[0],
            amount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        address[] memory withdrawers = setup.vault.pendingWithdrawers();
        assertEq(withdrawers.length, 1);

        uint256 snapshotId = vm.snapshot();
        vm.startPrank(address(setup.defaultBondStrategy));
        setup.vault.processWithdrawals(users);
        vm.stopPrank();
        vm.revertTo(snapshotId);

        vm.startPrank(admin);
        setup.vault.processWithdrawals(users);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(operator1);
        setup.vault.processWithdrawals(users);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(operator2);
        setup.vault.processWithdrawals(users);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.processWithdrawals(users);
        vm.stopPrank();
    }

    function testFuzz_VaultDelegateCall(address randomAddress) public {
        vm.assume(randomAddress != address(0));
        bytes memory data = abi.encode(1);

        vm.startPrank(admin);
        setup.vault.delegateCall(address(deployParams.defaultBondModule), data);
        vm.stopPrank();

        vm.startPrank(operator1);
        setup.vault.delegateCall(address(deployParams.defaultBondModule), data);
        vm.stopPrank();

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.delegateCall(address(deployParams.defaultBondModule), data);
        vm.stopPrank();

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.delegateCall(address(deployParams.defaultBondModule), data);
        vm.stopPrank();
    }

    function testFuzz_DefaultBondStrategyProcessAll(
        address randomAddress
    ) public {
        vm.assume(randomAddress != address(0));
        DefaultBondStrategy strategy = DefaultBondStrategy(
            setup.defaultBondStrategy
        );

        vm.startPrank(admin);
        strategy.processAll();
        vm.stopPrank();

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processAll();
        vm.stopPrank();

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processAll();
        vm.stopPrank();

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processAll();
        vm.stopPrank();
    }

    function testFuzz_DefaultBondStrategyProcessWithdrawals(
        address randomAddress
    ) public {
        vm.assume(randomAddress != address(0));

        address[] memory users = new address[](1);
        users[0] = vm.createWallet("user").addr;
        uint256 amount = 1 ether;

        vm.deal(users[0], amount);

        vm.startPrank(users[0]);
        setup.depositWrapper.deposit{value: amount}(
            users[0],
            address(0),
            amount,
            0,
            type(uint256).max
        );

        setup.vault.registerWithdrawal(
            users[0],
            amount,
            new uint256[](1),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        address[] memory withdrawers = setup.vault.pendingWithdrawers();
        assertEq(withdrawers.length, 1);

        DefaultBondStrategy strategy = DefaultBondStrategy(
            setup.defaultBondStrategy
        );

        uint256 snapshotId = vm.snapshot();

        vm.startPrank(admin);
        strategy.processWithdrawals(users);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processWithdrawals(users);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processWithdrawals(users);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processWithdrawals(users);
        vm.stopPrank();
    }

    function testFuzz_DefaultBondStrategyDepositCallback(
        address randomAddress
    ) public {
        vm.assume(randomAddress != address(0));
        DefaultBondStrategy strategy = DefaultBondStrategy(
            setup.defaultBondStrategy
        );

        vm.startPrank(admin);
        strategy.depositCallback(new uint256[](1), 0);
        vm.stopPrank();

        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.depositCallback(new uint256[](1), 0);
        vm.stopPrank();

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.depositCallback(new uint256[](1), 0);
        vm.stopPrank();

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.depositCallback(new uint256[](1), 0);
        vm.stopPrank();
    }

    function testFuzz_DefaultBondStrategySetData(
        address randomAddress,
        address randomToken
    ) public {
        vm.assume(randomAddress != address(0));
        vm.assume(randomToken != address(0));
        DefaultBondStrategy strategy = DefaultBondStrategy(
            setup.defaultBondStrategy
        );
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](1);
        data[0].bond = address(new DefaultBondMock(address(randomToken)));
        data[0].ratioX96 = Q96;
        uint256 snapshotId = vm.snapshot();

        vm.startPrank(admin);
        strategy.setData(randomToken, data);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(operator1);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.setData(randomToken, data);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.setData(randomToken, data);
        vm.stopPrank();

        vm.revertTo(snapshotId);
        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.setData(randomToken, data);
        vm.stopPrank();
    }

    function testFuzz_VaultExternalCall(address randomAddress) public {
        address uniswapV3Pool = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
        bytes4 selector = bytes4(0x3850c7bd);

        ManagedValidator validator = ManagedValidator(
            address(setup.configurator.validator())
        );

        vm.startPrank(admin);
        validator.grantContractSignatureRole(uniswapV3Pool, selector, 2);
        setup.configurator.stageValidator(address(validator));
        vm.warp(block.timestamp + 31 days);
        setup.configurator.commitValidator();
        setup.vault.externalCall(
            uniswapV3Pool,
            abi.encodeWithSelector(selector)
        );
        vm.stopPrank();

        vm.startPrank(operator1);
        setup.vault.externalCall(
            uniswapV3Pool,
            abi.encodeWithSelector(selector)
        );
        vm.stopPrank();

        vm.startPrank(operator2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.externalCall(
            uniswapV3Pool,
            abi.encodeWithSelector(selector)
        );
        vm.stopPrank();

        vm.startPrank(randomAddress);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        setup.vault.externalCall(
            uniswapV3Pool,
            abi.encodeWithSelector(selector)
        );
        vm.stopPrank();
    }
}
