// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../scripts/obol/Deploy.s.sol";

contract Integration is Test, DeployScript {
    using SafeERC20 for IERC20;

    bytes32 public constant ATTEST_MESSAGE_PREFIX =
        0xc7cfa471a8a16980de8314ea3a88ebcafb38ae7fb767d792017e90cf637d731b;

    function dep()
        public
        returns (
            DeployInterfaces.DeployParameters memory deployParams,
            DeployInterfaces.DeploySetup memory setup
        )
    {
        deployParams = DeployInterfaces.DeployParameters(
            DeployConstants.HOLESKY_DEPLOYER,
            DeployConstants.HOLESKY_PROXY_VAULT_ADMIN,
            DeployConstants.HOLESKY_VAULT_ADMIN,
            DeployConstants.HOLESKY_CURATOR_ADMIN,
            DeployConstants.HOLESKY_CURATOR_OPERATOR,
            DeployConstants.HOLESKY_LIDO_LOCATOR,
            DeployConstants.HOLESKY_WSTETH,
            DeployConstants.HOLESKY_STETH,
            DeployConstants.HOLESKY_WETH,
            DeployConstants.MAXIMAL_TOTAL_SUPPLY,
            DeployConstants.MELLOW_VAULT_NAME,
            DeployConstants.MELLOW_VAULT_SYMBOL,
            DeployConstants.INITIAL_DEPOSIT_ETH,
            DeployConstants.FIRST_DEPOSIT_ETH,
            Vault(payable(address(0))),
            Initializer(address(0)),
            ERC20TvlModule(address(0)),
            StakingModule(address(0)),
            ManagedRatiosOracle(address(0)),
            ChainlinkOracle(address(0)),
            IAggregatorV3(address(0)),
            IAggregatorV3(address(0)),
            DefaultProxyImplementation(address(0))
        );

        vm.startPrank(deployParams.deployer);
        deployParams = commonContractsDeploy(deployParams);
        (deployParams, setup) = deploy(deployParams);
        vm.stopPrank();
    }

    function simplifyDepositSecurityModule(
        DeployInterfaces.DeployParameters memory deployParams,
        Vm.Wallet memory guardian
    ) public {
        IDepositSecurityModule depositSecurityModule = IDepositSecurityModule(
            deployParams.stakingModule.lidoLocator().depositSecurityModule()
        );

        {
            address router = depositSecurityModule.STAKING_ROUTER();
            IStakingRouter.StakingModule memory module = IStakingRouter(router)
                .getStakingModule(DeployConstants.SIMPLE_DVT_MODULE_ID);
            // STAKING_MODULE_MANAGE_ROLE
            vm.prank(0xE92329EC7ddB11D25e25b3c21eeBf11f15eB325d);
            IStakingRouter(router).updateStakingModule(
                DeployConstants.SIMPLE_DVT_MODULE_ID,
                module.stakeShareLimit,
                module.priorityExitShareThreshold,
                module.stakingModuleFee,
                module.treasuryFee,
                type(uint256).max,
                1
            );
        }

        vm.startPrank(depositSecurityModule.getOwner());
        // depositSecurityModule.setMinDepositBlockDistance(1);
        depositSecurityModule.addGuardian(guardian.addr, 1);
        int256 guardianIndex = depositSecurityModule.getGuardianIndex(
            guardian.addr
        );
        assertTrue(guardianIndex >= 0);
        vm.stopPrank();
    }

    function getAllDepositParams(
        IDepositSecurityModule depositSecurityModule,
        uint256 blockNumber,
        Vm.Wallet memory guardian
    )
        public
        returns (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        )
    {
        blockHash = blockhash(blockNumber);
        assertNotEq(bytes32(0), blockHash);
        uint256 stakingModuleId = DeployConstants.SIMPLE_DVT_MODULE_ID;
        depositRoot = IDepositContract(depositSecurityModule.DEPOSIT_CONTRACT())
            .get_deposit_root();
        nonce = IStakingRouter(depositSecurityModule.STAKING_ROUTER())
            .getStakingModuleNonce(stakingModuleId);
        depositCalldata = new bytes(0);
        sigs = fetchSignatures(
            guardian,
            blockNumber,
            blockHash,
            depositRoot,
            stakingModuleId,
            nonce
        );
    }

    function fetchSignatures(
        Vm.Wallet memory guardian,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 stakingModuleId,
        uint256 nonce
    ) public returns (IDepositSecurityModule.Signature[] memory sigs) {
        bytes32 message = keccak256(
            abi.encodePacked(
                ATTEST_MESSAGE_PREFIX,
                blockNumber,
                blockHash,
                depositRoot,
                stakingModuleId,
                nonce
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(guardian, message);
        sigs = new IDepositSecurityModule.Signature[](1);
        uint8 parity = v - 27;
        sigs[0] = IDepositSecurityModule.Signature({
            r: r,
            vs: bytes32(uint256(s) | (uint256(parity) << 255))
        });
        address signerAddr = ecrecover(message, v, r, s);
        assertEq(signerAddr, guardian.addr);
    }

    // forge test -vvv --fork-url $(grep HOLESKY_RPC .env | cut -d '=' -f2,3,4,5) --match-path ./tests/holesky-obol/ObolTest.t.sol  --evm-version shanghai --fork-block-number 1881344
    function testObol() external {
        (
            DeployInterfaces.DeployParameters memory deployParams,
            DeployInterfaces.DeploySetup memory setup
        ) = dep();

        {
            address user = vm.createWallet("random-user-wallet-1234123").addr;
            vm.startPrank(user);
            deal(DeployConstants.HOLESKY_WETH, user, 1 ether);

            uint256[] memory amounts = new uint256[](2);
            uint256 wethIndex = DeployConstants.HOLESKY_WETH <
                DeployConstants.HOLESKY_WSTETH
                ? 0
                : 1;
            amounts[wethIndex] = 1 ether;
            amounts[wethIndex ^ 1] = 0;
            IERC20(DeployConstants.HOLESKY_WETH).safeIncreaseAllowance(
                address(setup.vault),
                1 ether
            );

            setup.vault.deposit(user, amounts, 1 ether, type(uint256).max, 0);
            console2.log(
                "User balance %x %d",
                user,
                setup.vault.balanceOf(user)
            );
            vm.stopPrank();
        }

        Vm.Wallet memory guardian = vm.createWallet("guardian");
        simplifyDepositSecurityModule(deployParams, guardian);
        uint256 blockNumber = block.number - 1;
        (
            bytes32 blockHash,
            bytes32 depositRoot,
            uint256 nonce,
            bytes memory depositCalldata,
            IDepositSecurityModule.Signature[] memory sigs
        ) = getAllDepositParams(
                IDepositSecurityModule(
                    deployParams
                        .stakingModule
                        .lidoLocator()
                        .depositSecurityModule()
                ),
                blockNumber,
                guardian
            );

        // 700k -> 1156k = 700k + 300k (weth->wsteth) + 156k (permissions/storage slots/e.t.c)
        uint256 amount = 1 ether;
        deal(DeployConstants.HOLESKY_WETH, address(setup.vault), amount);
        setup.strategy.convertAndDeposit(
            blockNumber,
            blockHash,
            depositRoot,
            nonce,
            depositCalldata,
            sigs
        );
        vm.stopPrank();
    }

    function testObolDeposit() external {
        (
            DeployInterfaces.DeployParameters memory deployParams,
            DeployInterfaces.DeploySetup memory setup
        ) = dep();

        for (uint256 i = 0; i < 10; i++) {
            address user = vm.createWallet("random-user-wallet-1234123").addr;

            vm.startPrank(user);
            deal(DeployConstants.HOLESKY_WETH, user, 1 ether);

            uint256[] memory amounts = new uint256[](2);
            uint256 wethIndex = DeployConstants.HOLESKY_WETH <
                DeployConstants.HOLESKY_WSTETH
                ? 0
                : 1;
            amounts[wethIndex] = 1 ether;
            amounts[1 - wethIndex] = 0;
            IERC20(DeployConstants.HOLESKY_WETH).safeIncreaseAllowance(
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
