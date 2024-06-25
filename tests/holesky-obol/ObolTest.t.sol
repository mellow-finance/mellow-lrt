// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "forge-std/Test.sol";

import "../../scripts/holesky-obol/Deploy.s.sol";

contract Integration is Test, DeployScript {
    using SafeERC20 for IERC20;

    function dep()
        public
        returns (
            DeployInterfaces.DeployParameters memory deployParams,
            DeployInterfaces.DeploySetup memory setup
        )
    {
        deployParams = DeployInterfaces.DeployParameters({
            deployer: DeployConstants.HOLESKY_DEPLOYER,
            proxyAdmin: DeployConstants.PROXY_VAULT_ADMIN,
            admin: DeployConstants.VAULT_ADMIN,
            curatorAdmin: DeployConstants.CURATOR_ADMIN,
            curatorOperator: DeployConstants.CURATOR_ADMIN,
            lpTokenName: DeployConstants.MELLOW_VAULT_NAME,
            lpTokenSymbol: DeployConstants.MELLOW_VAULT_SYMBOL,
            wsteth: DeployConstants.WSTETH,
            steth: DeployConstants.STETH,
            weth: DeployConstants.WETH,
            maximalTotalSupply: DeployConstants.MAXIMAL_TOTAL_SUPPLY,
            initialDepositETH: DeployConstants.INITIAL_DEPOSIT_ETH,
            firstDepositETH: DeployConstants.FIRST_DEPOSIT_ETH,
            initializer: Initializer(address(0)),
            initialImplementation: Vault(payable(address(0))),
            erc20TvlModule: ERC20TvlModule(address(0)),
            stakingModule: StakingModule(address(0)),
            ratiosOracle: ManagedRatiosOracle(address(0)),
            priceOracle: ChainlinkOracle(address(0)),
            wethAggregatorV3: IAggregatorV3(address(0)),
            wstethAggregatorV3: IAggregatorV3(address(0)),
            defaultProxyImplementation: DefaultProxyImplementation(address(0))
        });

        vm.startPrank(deployParams.deployer);
        deployParams = commonContractsDeploy(deployParams);
        (deployParams, setup) = deploy(deployParams);
        vm.stopPrank();
    }

    // initial test
    function testObol() external {
        (
            DeployInterfaces.DeployParameters memory deployParams,
            DeployInterfaces.DeploySetup memory setup
        ) = dep();

        for (uint256 i = 0; i < 10; i++) {
            address user = vm.createWallet("random-user-wallet-1234123").addr;

            vm.startPrank(user);
            deal(DeployConstants.WETH, user, 1 ether);

            uint256[] memory amounts = new uint256[](2);
            uint256 wethIndex = DeployConstants.WETH < DeployConstants.WSTETH
                ? 0
                : 1;
            amounts[wethIndex] = 1 ether;
            amounts[1 - wethIndex] = 0;
            IERC20(DeployConstants.WETH).safeIncreaseAllowance(
                address(setup.vault),
                1 ether
            );

            setup.vault.deposit(user, amounts, 1 ether, type(uint256).max, 0);
            console2.log(
                "User balance %x %d",
                address(user),
                setup.vault.balanceOf(user)
            );
            vm.stopPrank();
        }
    }
}
