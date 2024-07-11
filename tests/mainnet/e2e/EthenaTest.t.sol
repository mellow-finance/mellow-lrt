// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../scripts/mainnet-ethena/DeployScript.sol";
import "../../../scripts/mainnet-ethena/Validator.sol";

contract FuzzingDepositWithdrawTest is DeployScript, Validator, Test {
    using SafeERC20 for IERC20;

    DeployInterfaces.DeployParameters deployParams;
    DeployInterfaces.DeploySetup setup;

    uint256 public constant MAX_USERS = 4;
    uint256 public constant MAX_ERROR_DEPOSIT = 4 wei;
    uint256 public constant Q96 = 2 ** 96;

    function testSUSDE() external {
        string memory name = DeployConstants.SUSDE_VAULT_NAME;
        string memory symbol = DeployConstants.SUSDE_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_DEPLOYER;
        vm.startPrank(deployParams.deployer);

        deployParams.proxyAdmin = DeployConstants.MELLOW_ETHENA_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_ETHENA_MULTISIG;

        deployParams.defaultBondFactory = DeployConstants.DEFAULT_BOND_FACTORY;
        deployParams.defaultBond = DeployConstants.SUSDE_DEFAULT_BOND;

        deployParams.maximalTotalSupply = 100 ether;
        deployParams.initialDeposit = 1 ether;
        deployParams = commonContractsDeploy(deployParams);
        deployParams.curators = new address[](3);
        deployParams.curators[0] = DeployConstants.ETHENA_CURATOR_MEV;
        deployParams.curators[1] = DeployConstants.ETHENA_CURATOR_RE7;
        deployParams.curators[2] = DeployConstants.ETHENA_CURATOR_NEXO;

        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;
        deployParams.underlyingToken = DeployConstants.SUSDE;

        deal(
            deployParams.underlyingToken,
            deployParams.deployer,
            deployParams.initialDeposit
        );
        (deployParams, setup) = deploy(deployParams);

        validateParameters(deployParams, setup, 0);
        vm.stopPrank();

        for (uint256 i = 0; i < 10; i++) {
            address user = address(
                bytes20(bytes32(keccak256(abi.encodePacked("user-", i))))
            );
            vm.startPrank(user);
            deal(deployParams.underlyingToken, user, 1 ether);
            IERC20(deployParams.underlyingToken).approve(
                address(setup.vault),
                1 ether
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 1 ether;
            IVault(setup.vault).deposit(user, amounts, 0, type(uint256).max,
                0);

            vm.stopPrank();

            console2.log(
                "User balance: ",
                user,
                IERC20(address(setup.vault)).balanceOf(user)
            );
        }

        for (uint256 i = 0; i < 10; i++) {
            address user = address(
                bytes20(bytes32(keccak256(abi.encodePacked("user-", i))))
            );
            vm.startPrank(user);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 1 ether;
            IVault(setup.vault).registerWithdrawal(
                user,
                1 ether,
                amounts,
                type(uint256).max,
                type(uint256).max,
                false
            );
            vm.stopPrank();
        }

        vm.startPrank(deployParams.admin);
        setup.defaultBondStrategy.processAll();
        vm.stopPrank();
    }

    // forge test -vvv --fork-url $(grep MAINNET_RPC .env | cut -d '=' -f2,3,4,5) --fork-block-number 20160000 --match-path ./tests/mainnet/e2e/EthenaTest.t.sol  --evm-version shanghai
    function testENA() external {
        string memory name = DeployConstants.ENA_VAULT_NAME;
        string memory symbol = DeployConstants.ENA_VAULT_SYMBOL;

        deployParams.deployer = DeployConstants.MAINNET_DEPLOYER;
        vm.startPrank(deployParams.deployer);

        deployParams.proxyAdmin = DeployConstants.MELLOW_ETHENA_PROXY_MULTISIG;
        deployParams.admin = DeployConstants.MELLOW_ETHENA_MULTISIG;

        deployParams.defaultBondFactory = DeployConstants.DEFAULT_BOND_FACTORY;
        deployParams.defaultBond = DeployConstants.ENA_DEFAULT_BOND;

        deployParams.maximalTotalSupply = 100 ether;
        deployParams.initialDeposit = 1 ether;
        deployParams = commonContractsDeploy(deployParams);
        deployParams.curators = new address[](3);
        deployParams.curators[0] = DeployConstants.ETHENA_CURATOR_MEV;
        deployParams.curators[1] = DeployConstants.ETHENA_CURATOR_RE7;
        deployParams.curators[2] = DeployConstants.ETHENA_CURATOR_NEXO;
        deployParams.lpTokenName = name;
        deployParams.lpTokenSymbol = symbol;
        deployParams.underlyingToken = DeployConstants.ENA;

        deal(
            deployParams.underlyingToken,
            deployParams.deployer,
            deployParams.initialDeposit
        );
        (deployParams, setup) = deploy(deployParams);

        validateParameters(deployParams, setup, 0);
        vm.stopPrank();

        for (uint256 i = 0; i < 10; i++) {
            address user = address(
                bytes20(bytes32(keccak256(abi.encodePacked("user-", i))))
            );
            vm.startPrank(user);
            deal(deployParams.underlyingToken, user, 1 ether);
            IERC20(deployParams.underlyingToken).approve(
                address(setup.vault),
                1 ether
            );
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 1 ether;
            IVault(setup.vault).deposit(user, amounts, 0, type(uint256).max,
                0);

            vm.stopPrank();

            console2.log(
                "User balance: ",
                user,
                IERC20(address(setup.vault)).balanceOf(user)
            );
        }

        for (uint256 i = 0; i < 10; i++) {
            address user = address(
                bytes20(bytes32(keccak256(abi.encodePacked("user-", i))))
            );
            vm.startPrank(user);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 1 ether;
            IVault(setup.vault).registerWithdrawal(
                user,
                1 ether,
                amounts,
                type(uint256).max,
                type(uint256).max,
                false
            );
            vm.stopPrank();
        }

        vm.startPrank(deployParams.admin);
        setup.defaultBondStrategy.processAll();
        vm.stopPrank();
    }
}
