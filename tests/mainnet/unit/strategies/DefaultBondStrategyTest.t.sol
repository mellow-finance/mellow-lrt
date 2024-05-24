// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";

contract Unit is Test {
    using SafeERC20 for IERC20;

    address public immutable strategyAdmin =
        address(bytes20(keccak256("strategy-admin")));
    address public immutable admin = address(bytes20(keccak256("vault-admin")));
    address public immutable operator =
        address(bytes20(keccak256("vault-operator")));

    function testConstructor() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            erc20TvlModule,
            bondModule
        );

        strategy.requireAdmin(strategyAdmin);

        assertEq(address(strategy.vault()), address(vault));
        assertEq(address(strategy.erc20TvlModule()), address(erc20TvlModule));
        assertEq(address(strategy.bondModule()), address(bondModule));
    }

    function testConstructorZeroAddresses() external {
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            IVault(address(0)),
            IERC20TvlModule(address(0)),
            IDefaultBondModule(address(0))
        );

        strategy.requireAdmin(strategyAdmin);

        assertEq(address(strategy.vault()), address(0));
        assertEq(address(strategy.erc20TvlModule()), address(0));
        assertEq(address(strategy.bondModule()), address(0));
    }

    function testSetData() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            erc20TvlModule,
            bondModule
        );

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(address(1)));
        data[1].bond = address(new DefaultBondMock(address(1)));
        data[0].ratioX96 = 2 ** 96 / 2;
        data[1].ratioX96 = 2 ** 96 / 2;

        strategy.setData(address(1), data);

        bytes memory data_ = strategy.tokenToData(address(1));

        assertEq(keccak256(data_), keccak256(abi.encode(data)));

        vm.stopPrank();
    }

    function testSetDataFailsWithForbidden() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            erc20TvlModule,
            bondModule
        );

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.setData(address(1), new IDefaultBondStrategy.Data[](0));
    }

    function testSetDataFailsWithAddressZero() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            erc20TvlModule,
            bondModule
        );

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(address(1)));
        data[1].bond = address(new DefaultBondMock(address(1)));
        data[0].ratioX96 = 2 ** 96 / 2;
        data[1].ratioX96 = 2 ** 96 / 2;

        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        strategy.setData(address(0), data);
        data[1].bond = address(0);
        vm.expectRevert(abi.encodeWithSignature("AddressZero()"));
        strategy.setData(address(1), data);
        vm.stopPrank();
    }

    function testSetDataFailsWithInvalidCumulativeRatio() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            erc20TvlModule,
            bondModule
        );

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(address(1)));
        data[1].bond = address(new DefaultBondMock(address(1)));
        data[0].ratioX96 = 2 ** 96 / 2;
        data[1].ratioX96 = 2 ** 96 / 2 - 1;

        vm.expectRevert(abi.encodeWithSignature("InvalidCumulativeRatio()"));
        strategy.setData(address(1), data);
        vm.stopPrank();
    }

    function testSetDataFailsWithInvalidBond() external {
        Vault vault = new Vault("Mellow LRT Vault", "mLRT", admin);
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            erc20TvlModule,
            bondModule
        );

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(address(1)));
        data[1].bond = address(new DefaultBondMock(address(2)));
        data[0].ratioX96 = 2 ** 96 / 2;
        data[1].ratioX96 = 2 ** 96 / 2;

        vm.expectRevert(abi.encodeWithSignature("InvalidBond()"));
        strategy.setData(address(1), data);
        vm.stopPrank();
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

    function _setUp(Vault vault) private {
        ERC20TvlModule erc20TvlModule = new ERC20TvlModule();
        vault.addTvlModule(address(erc20TvlModule));

        vault.addToken(Constants.WSTETH);
        vault.addToken(Constants.RETH);
        vault.addToken(Constants.WETH);
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );

        {
            configurator.stageValidator(address(new ManagedValidator(admin)));
            configurator.commitValidator();
        }

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
                new WStethRatiosAggregatorV3(Constants.WSTETH)
            );
            oracles[1] = Constants.RETH_CHAINLINK_ORACLE;
            oracles[2] = address(new ConstantAggregatorV3(1 ether));

            chainlinkOracle.setChainlinkOracles(
                address(vault),
                tokens,
                _convert(oracles)
            );

            configurator.stagePriceOracle(address(chainlinkOracle));
            configurator.commitPriceOracle();
        }

        configurator.stageMaximalTotalSupply(1000 ether);
        configurator.commitMaximalTotalSupply();
    }

    function _setupDepositPermissions(IVault vault) private {
        VaultConfigurator configurator = VaultConfigurator(
            address(vault.configurator())
        );
        uint8 depositRole = 14;
        IManagedValidator validator = IManagedValidator(
            configurator.validator()
        );
        if (address(validator) == address(0)) {
            validator = new ManagedValidator(admin);
            configurator.stageValidator(address(validator));
            configurator.commitValidator();
        }
        validator.grantPublicRole(depositRole);
        validator.grantContractSignatureRole(
            address(vault),
            IVault.deposit.selector,
            depositRole
        );
    }

    function _initialDeposit(Vault vault) private {
        vm.startPrank(admin);
        _setupDepositPermissions(vault);
        vm.stopPrank();

        vm.startPrank(operator);

        deal(Constants.WSTETH, operator, 10 gwei);
        deal(Constants.RETH, operator, 0 ether);
        deal(Constants.WETH, operator, 0 ether);
        IERC20(Constants.WSTETH).safeIncreaseAllowance(address(vault), 10 gwei);

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

    function testDepositCallbackEmpty() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
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
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.stopPrank();
    }

    function testDepositCallbackFailsWithForbidden() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();

        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 2 ** 96 / 2;
        data[1].ratioX96 = 2 ** 96 / 2;
        strategy.setData(Constants.WSTETH, data);

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

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);

        vm.stopPrank();
    }

    function testDepositCallbackWithBonds() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();

        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vm.stopPrank();

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0);
        assertEq(
            IERC20(data[1].bond).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
    }

    function testDepositCallbackWithBondsWithoutDepositCallback() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );
        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        strategy.depositCallback(new uint256[](0), 0);
        vm.stopPrank();

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0);
        assertEq(
            IERC20(data[1].bond).balanceOf(address(vault)),
            10 ether + 10 gwei
        );
    }

    function testDepositCallbackWithBondsWithoutDepositCallbackFailsWithForbidden()
        external
    {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );
        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.depositCallback(new uint256[](0), 0);
    }

    function testProcessAll() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();

        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );
        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        strategy.processAll();
        vm.stopPrank();

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0 gwei);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(depositor)),
            10 ether
        );
        assertEq(IERC20(data[1].bond).balanceOf(address(vault)), 10 gwei);
    }

    function testprocessWithdrawalsOnBehalfOfUser() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();

        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );

        address[] memory users = new address[](1);
        users[0] = depositor;
        strategy.processWithdrawals(users);
        vm.stopPrank();

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0 gwei);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(depositor)),
            10 ether
        );
        assertEq(IERC20(data[1].bond).balanceOf(address(vault)), 10 gwei);
    }

    function testprocessWithdrawalsOnBehalfOfOperator() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();

        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );

        address[] memory users = new address[](1);
        users[0] = depositor;
        vm.stopPrank();

        vm.prank(strategyAdmin);
        strategy.processWithdrawals(users);

        assertEq(IERC20(Constants.WSTETH).balanceOf(address(vault)), 0 gwei);
        assertEq(
            IERC20(Constants.WSTETH).balanceOf(address(depositor)),
            10 ether
        );
        assertEq(IERC20(data[1].bond).balanceOf(address(vault)), 10 gwei);
    }

    function testprocessWithdrawalsFailsWithForbidden() external {
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

        DefaultBondModule bondModule = new DefaultBondModule();
        DefaultBondStrategy strategy = new DefaultBondStrategy(
            strategyAdmin,
            vault,
            IERC20TvlModule(vault.tvlModules()[0]),
            bondModule
        );

        configurator.stageDepositCallback(address(strategy));
        configurator.commitDepositCallback();

        ManagedValidator validator = ManagedValidator(
            address(configurator.validator())
        );

        uint8 bondModuleRole = 1;

        validator.grantRole(address(strategy), bondModuleRole);
        validator.grantRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(vault), bondModuleRole);
        validator.grantContractRole(address(bondModule), bondModuleRole);
        configurator.stageDelegateModuleApproval(address(bondModule));
        configurator.commitDelegateModuleApproval(address(bondModule));

        vault.grantRole(vault.OPERATOR(), address(strategy));

        vm.stopPrank();

        vm.startPrank(strategyAdmin);
        IDefaultBondStrategy.Data[]
            memory data = new IDefaultBondStrategy.Data[](2);
        data[0].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[1].bond = address(new DefaultBondMock(Constants.WSTETH));
        data[0].ratioX96 = 0;
        data[1].ratioX96 = 2 ** 96;
        strategy.setData(Constants.WSTETH, data);
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

        vault.deposit(depositor, amounts, 10 ether, type(uint256).max);
        vault.registerWithdrawal(
            depositor,
            10 ether,
            new uint256[](3),
            type(uint256).max,
            type(uint256).max,
            false
        );

        address[] memory users = new address[](1);
        users[0] = depositor;
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        strategy.processWithdrawals(users);
    }
}
