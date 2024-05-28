// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../../src/security/AdminProxy.sol";
import "../../Constants.sol";

contract Unit is Test {
    address public deployer = vm.createWallet("deployer").addr;
    address public proposer = vm.createWallet("proposer").addr;
    address public acceptor = vm.createWallet("acceptor").addr;
    address public emergencyOperator =
        vm.createWallet("emergencyOperator").addr;

    function testConstructor() external {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(this),
            address(this),
            new bytes(0)
        );
        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            address(this),
            address(this),
            address(this),
            address(this),
            IAdminProxy.Proposal({
                implementation: address(this),
                callData: new bytes(0)
            })
        );

        assertEq(address(adminProxy.proxy()), address(proxy));
        assertEq(address(adminProxy.proposer()), address(this));
        assertEq(address(adminProxy.acceptor()), address(this));
        assertEq(address(adminProxy.emergencyOperator()), address(this));
        assertEq(adminProxy.baseImplementation().implementation, address(this));
        assertEq(adminProxy.baseImplementation().callData.length, 0);
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            address(0)
        );
        assertEq(adminProxy.proposalsCount(), 0);
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 0);
        assertEq(adminProxy.latestAcceptedNonce(), 0);
    }

    function testConstructorZeroParams() external {
        {
            vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
            new AdminProxy(
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                IAdminProxy.Proposal({
                    implementation: address(0),
                    callData: new bytes(0)
                })
            );
        }

        AdminProxy adminProxy = new AdminProxy(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );
        assertEq(address(adminProxy.proxy()), address(0));
        assertEq(address(adminProxy.proposer()), address(0));
        assertEq(address(adminProxy.acceptor()), address(0));
        assertEq(address(adminProxy.emergencyOperator()), address(0));
        assertEq(adminProxy.baseImplementation().implementation, address(1));
        assertEq(adminProxy.baseImplementation().callData.length, 0);
        assertEq(adminProxy.latestAcceptedNonce(), 0);
        vm.expectRevert();
        adminProxy.proposalAt(0);
        vm.expectRevert();
        adminProxy.proposalAt(1);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeAcceptor(acceptor);
        vm.startPrank(address(0));
        adminProxy.upgradeAcceptor(acceptor);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeAcceptor(acceptor);
        vm.stopPrank();
    }

    function testUpdateEmergencyOperator() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();
        vm.startPrank(acceptor);

        assertEq(adminProxy.emergencyOperator(), emergencyOperator);

        address newEmergencyOperator = vm
            .createWallet("newEmergencyOperator")
            .addr;

        adminProxy.upgradeEmergencyOperator(newEmergencyOperator);
        assertEq(adminProxy.emergencyOperator(), newEmergencyOperator);

        vm.stopPrank();
    }

    function testUpdateProposer() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();
        vm.startPrank(acceptor);

        assertEq(adminProxy.proposer(), proposer);

        address newProposer = vm.createWallet("newProposer").addr;

        adminProxy.upgradeProposer(newProposer);
        assertEq(adminProxy.proposer(), newProposer);

        vm.stopPrank();
    }

    function testUpdateAcceptor() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();
        vm.startPrank(acceptor);

        assertEq(adminProxy.acceptor(), acceptor);

        address newAcceptor = vm.createWallet("newAcceptor").addr;

        adminProxy.upgradeAcceptor(newAcceptor);
        assertEq(adminProxy.acceptor(), newAcceptor);

        vm.stopPrank();
    }

    function testUpdateEmergencyOperatorFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();
        vm.startPrank(acceptor);

        assertEq(adminProxy.emergencyOperator(), emergencyOperator);

        address newEmergencyOperator = vm
            .createWallet("newEmergencyOperator")
            .addr;

        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeEmergencyOperator(newEmergencyOperator);

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeEmergencyOperator(newEmergencyOperator);
        vm.stopPrank();
        vm.startPrank(emergencyOperator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeEmergencyOperator(newEmergencyOperator);
        vm.stopPrank();
    }

    function testUpdateProposerFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();
        vm.startPrank(acceptor);

        assertEq(adminProxy.proposer(), proposer);

        address newProposer = vm.createWallet("newProposer").addr;

        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeProposer(newProposer);

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeProposer(newProposer);
        vm.stopPrank();
        vm.startPrank(emergencyOperator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeProposer(newProposer);
        vm.stopPrank();
    }

    function testUpdateAcceptorFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();
        vm.startPrank(acceptor);

        assertEq(adminProxy.acceptor(), acceptor);

        address newAcceptor = vm.createWallet("newAcceptor").addr;

        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeAcceptor(newAcceptor);

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeAcceptor(newAcceptor);
        vm.stopPrank();
        vm.startPrank(emergencyOperator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.upgradeAcceptor(newAcceptor);
        vm.stopPrank();
    }

    function testProposeBaseImplementation() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.proposeBaseImplementation(proposal1, new bytes(5));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            proposal1
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 5);
        vm.stopPrank();

        vm.startPrank(acceptor);
        address proposal2 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.proposeBaseImplementation(proposal2, new bytes(6));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            proposal2
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 6);
        vm.stopPrank();
    }

    function testProposeBaseImplementationFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(emergencyOperator);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.proposeBaseImplementation(proposal1, new bytes(5));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            address(0)
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 0);
        vm.stopPrank();

        address proposal2 = address(new VaultMock(Constants.VAULT_ADMIN));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.proposeBaseImplementation(proposal2, new bytes(6));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            address(0)
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 0);

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.proposeBaseImplementation(address(0), new bytes(0));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            address(0)
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 0);
        vm.stopPrank();
    }

    function testPropose() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.propose(proposal1, new bytes(5));
        assertEq(adminProxy.proposalsCount(), 1);
        assertEq(adminProxy.proposalAt(1).implementation, proposal1);
        assertEq(adminProxy.proposalAt(1).callData.length, 5);
        vm.stopPrank();

        vm.startPrank(acceptor);
        address proposal2 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.propose(proposal2, new bytes(6));
        assertEq(adminProxy.proposalsCount(), 2);
        assertEq(adminProxy.proposalAt(2).implementation, proposal2);
        assertEq(adminProxy.proposalAt(2).callData.length, 6);
        vm.stopPrank();
    }

    function testProposeFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(emergencyOperator);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.propose(proposal1, new bytes(5));
        assertEq(adminProxy.proposalsCount(), 0);
        vm.stopPrank();

        address proposal2 = address(new VaultMock(Constants.VAULT_ADMIN));
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.propose(proposal2, new bytes(6));
        assertEq(adminProxy.proposalsCount(), 0);

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.propose(address(0), new bytes(0));
        vm.stopPrank();
    }

    function testAcceptBaseImplementation() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.proposeBaseImplementation(proposal, new bytes(5));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            proposal
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 5);
        vm.stopPrank();

        vm.startPrank(acceptor);
        adminProxy.acceptBaseImplementation();
        assertEq(adminProxy.baseImplementation().implementation, proposal);
        assertEq(adminProxy.baseImplementation().callData.length, 5);
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            address(0)
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 0);
        vm.stopPrank();
    }

    function testAcceptBaseImplementationFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.proposeBaseImplementation(proposal, new bytes(5));
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            proposal
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 5);

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptBaseImplementation();
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            proposal
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 5);
        vm.stopPrank();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptBaseImplementation();
        assertEq(
            adminProxy.proposedBaseImplementation().implementation,
            proposal
        );
        assertEq(adminProxy.proposedBaseImplementation().callData.length, 5);
    }

    function testAcceptProposal() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.propose(proposal1, new bytes(5));
        assertEq(adminProxy.proposalsCount(), 1);
        assertEq(adminProxy.proposalAt(1).implementation, proposal1);
        assertEq(adminProxy.proposalAt(1).callData.length, 5);
        vm.stopPrank();

        vm.startPrank(acceptor);
        // due to invalid callData
        vm.expectRevert();
        adminProxy.acceptProposal(1);
        vm.stopPrank();

        vm.startPrank(proposer);
        adminProxy.propose(proposal1, new bytes(0));
        assertEq(adminProxy.proposalsCount(), 2);
        assertEq(adminProxy.proposalAt(2).implementation, proposal1);
        assertEq(adminProxy.proposalAt(2).callData.length, 0);
        vm.stopPrank();

        vm.startPrank(acceptor);
        adminProxy.acceptProposal(2);
        assertEq(adminProxy.latestAcceptedNonce(), 2);
        assertEq(adminProxy.proposalsCount(), 2);

        address newImplementation = address(
            uint160(
                uint256(
                    vm.load(address(proxy), ERC1967Utils.IMPLEMENTATION_SLOT)
                )
            )
        );
        assertEq(newImplementation, adminProxy.proposalAt(2).implementation);
        vm.stopPrank();
    }

    function testAcceptProposalFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.propose(proposal1, new bytes(5));
        assertEq(adminProxy.proposalsCount(), 1);
        assertEq(adminProxy.proposalAt(1).implementation, proposal1);
        assertEq(adminProxy.proposalAt(1).callData.length, 5);
        vm.stopPrank();

        vm.startPrank(acceptor);
        // due to invalid callData
        vm.expectRevert();
        adminProxy.acceptProposal(1);
        vm.stopPrank();

        vm.startPrank(proposer);
        adminProxy.propose(proposal1, new bytes(0));
        assertEq(adminProxy.proposalsCount(), 2);
        assertEq(adminProxy.proposalAt(2).implementation, proposal1);
        assertEq(adminProxy.proposalAt(2).callData.length, 0);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(0);

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(0);
        vm.stopPrank();

        vm.startPrank(emergencyOperator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(0);
        vm.stopPrank();

        vm.startPrank(acceptor);
        adminProxy.acceptProposal(2);
        assertEq(adminProxy.latestAcceptedNonce(), 2);
        assertEq(adminProxy.proposalsCount(), 2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(2);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.acceptProposal(3);

        vm.stopPrank();
    }

    function testRejectAllProposals() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        assertEq(adminProxy.proposalsCount(), 5);
        vm.stopPrank();

        vm.startPrank(acceptor);
        assertEq(adminProxy.latestAcceptedNonce(), 0);
        adminProxy.rejectAllProposals();
        assertEq(adminProxy.latestAcceptedNonce(), 5);
        vm.stopPrank();
    }

    function testRejectAllProposalsFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        vm.startPrank(deployer);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));
        vm.stopPrank();

        vm.startPrank(proposer);
        address proposal1 = address(new VaultMock(Constants.VAULT_ADMIN));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        adminProxy.propose(proposal1, new bytes(0));
        assertEq(adminProxy.proposalsCount(), 5);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.rejectAllProposals();

        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.rejectAllProposals();
        vm.stopPrank();

        vm.startPrank(emergencyOperator);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.rejectAllProposals();
        vm.stopPrank();
    }

    function testResetToBaseImplementationZeroAddress() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: address(1),
                callData: new bytes(0)
            })
        );

        vm.prank(deployer);
        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));

        address currentImplementation = address(
            uint160(
                uint256(
                    vm.load(address(proxy), ERC1967Utils.IMPLEMENTATION_SLOT)
                )
            )
        );

        assertEq(currentImplementation, initialImplementation);
        assertEq(address(1), adminProxy.baseImplementation().implementation);

        vm.startPrank(emergencyOperator);

        vm.expectRevert();
        adminProxy.resetToBaseImplementation();

        vm.stopPrank();
    }

    function testResetToBaseImplementationNonZeroAddress() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        address baseImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: baseImplementation,
                callData: new bytes(0)
            })
        );

        vm.prank(deployer);
        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));

        address currentImplementation = address(
            uint160(
                uint256(
                    vm.load(address(proxy), ERC1967Utils.IMPLEMENTATION_SLOT)
                )
            )
        );

        assertEq(currentImplementation, initialImplementation);

        vm.prank(emergencyOperator);
        adminProxy.resetToBaseImplementation();

        address newImplementation = address(
            uint160(
                uint256(
                    vm.load(address(proxy), ERC1967Utils.IMPLEMENTATION_SLOT)
                )
            )
        );

        assertEq(newImplementation, baseImplementation);
        assertEq(address(0), adminProxy.emergencyOperator());
    }

    function testResetToBaseImplementationFailsWithForbidden() external {
        address initialImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            initialImplementation,
            deployer,
            new bytes(0)
        );

        // any better way to fetch this ProxyAdmin address?
        address immutableProxyAdmin = address(
            uint160(uint256(vm.load(address(proxy), ERC1967Utils.ADMIN_SLOT)))
        );

        address baseImplementation = address(
            new VaultMock(Constants.VAULT_ADMIN)
        );

        AdminProxy adminProxy = new AdminProxy(
            address(proxy),
            immutableProxyAdmin,
            acceptor,
            proposer,
            emergencyOperator,
            IAdminProxy.Proposal({
                implementation: baseImplementation,
                callData: new bytes(0)
            })
        );

        vm.prank(deployer);
        ProxyAdmin(immutableProxyAdmin).transferOwnership(address(adminProxy));

        address currentImplementation = address(
            uint160(
                uint256(
                    vm.load(address(proxy), ERC1967Utils.IMPLEMENTATION_SLOT)
                )
            )
        );

        assertEq(currentImplementation, initialImplementation);

        vm.startPrank(acceptor);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.resetToBaseImplementation();
        vm.stopPrank();
        vm.startPrank(proposer);
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.resetToBaseImplementation();
        vm.stopPrank();

        vm.startPrank(emergencyOperator);
        adminProxy.resetToBaseImplementation();
        vm.expectRevert(abi.encodeWithSignature("Forbidden()"));
        adminProxy.resetToBaseImplementation();
        vm.stopPrank();
    }
}
