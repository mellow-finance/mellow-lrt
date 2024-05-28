// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/security/IAdminProxy.sol";

contract AdminProxy is IAdminProxy {
    /// @inheritdoc IAdminProxy
    ITransparentUpgradeableProxy public immutable proxy;
    /// @inheritdoc IAdminProxy
    ProxyAdmin public immutable proxyAdmin;
    /// @inheritdoc IAdminProxy
    address public proposer;
    /// @inheritdoc IAdminProxy
    address public acceptor;
    /// @inheritdoc IAdminProxy
    address public emergencyOperator;
    /// @inheritdoc IAdminProxy
    uint256 public latestAcceptedNonce;

    Proposal private _baseImplementation;
    Proposal private _proposedBaseImplementation;
    Proposal[] private _proposals;

    constructor(
        address proxy_,
        address proxyAdmin_,
        address acceptor_,
        address proposer_,
        address emergencyOperator_,
        Proposal memory baseImplementation_
    ) {
        proxy = ITransparentUpgradeableProxy(proxy_);
        proxyAdmin = ProxyAdmin(proxyAdmin_);
        acceptor = acceptor_;
        proposer = proposer_;
        emergencyOperator = emergencyOperator_;
        if (baseImplementation_.implementation == address(0))
            revert Forbidden();
        _baseImplementation = baseImplementation_;
    }

    modifier requireProposerOrAcceptor() {
        if (msg.sender != proposer && msg.sender != acceptor)
            revert Forbidden();
        _;
    }

    modifier onlyAcceptor() {
        if (msg.sender != acceptor) revert Forbidden();
        _;
    }

    modifier onlyEmergencyOperator() {
        if (msg.sender != emergencyOperator) revert Forbidden();
        _;
    }

    /// @inheritdoc IAdminProxy
    function baseImplementation() external view returns (Proposal memory) {
        return _baseImplementation;
    }

    /// @inheritdoc IAdminProxy
    function proposedBaseImplementation()
        external
        view
        returns (Proposal memory)
    {
        return _proposedBaseImplementation;
    }

    /// @inheritdoc IAdminProxy
    function proposalAt(uint256 index) external view returns (Proposal memory) {
        return _proposals[index - 1];
    }

    /// @inheritdoc IAdminProxy
    function proposalsCount() external view returns (uint256) {
        return _proposals.length;
    }

    /// @inheritdoc IAdminProxy
    function upgradeEmergencyOperator(
        address newEmergencyOperator
    ) external onlyAcceptor {
        emergencyOperator = newEmergencyOperator;
        emit EmergencyOperatorUpgraded(newEmergencyOperator, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function upgradeProposer(address newProposer) external onlyAcceptor {
        proposer = newProposer;
        emit ProposerUpgraded(newProposer, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function upgradeAcceptor(address newAcceptor) external onlyAcceptor {
        acceptor = newAcceptor;
        emit AcceptorUpgraded(newAcceptor, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function proposeBaseImplementation(
        address implementation,
        bytes calldata callData
    ) external requireProposerOrAcceptor {
        if (implementation == address(0)) revert Forbidden();
        _proposedBaseImplementation = Proposal({
            implementation: implementation,
            callData: callData
        });
        emit BaseImplementationProposed(_proposedBaseImplementation, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function propose(
        address implementation,
        bytes calldata callData
    ) external requireProposerOrAcceptor {
        if (implementation == address(0)) revert Forbidden();
        _proposals.push(
            Proposal({implementation: implementation, callData: callData})
        );
        emit ImplementationProposed(implementation, callData, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function acceptBaseImplementation() external onlyAcceptor {
        _baseImplementation = _proposedBaseImplementation;
        delete _proposedBaseImplementation;
        emit BaseImplementationAccepted(_baseImplementation, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function acceptProposal(uint256 index) external onlyAcceptor {
        if (index <= latestAcceptedNonce || _proposals.length < index)
            revert Forbidden();
        Proposal memory proposal = _proposals[index - 1];
        proxyAdmin.upgradeAndCall(
            proxy,
            proposal.implementation,
            proposal.callData
        );
        latestAcceptedNonce = index;
        emit ProposalAccepted(index, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function rejectAllProposals() external onlyAcceptor {
        latestAcceptedNonce = _proposals.length;
        emit AllProposalsRejected(latestAcceptedNonce, tx.origin);
    }

    /// @inheritdoc IAdminProxy
    function resetToBaseImplementation() external onlyEmergencyOperator {
        proxyAdmin.upgradeAndCall(
            proxy,
            _baseImplementation.implementation,
            _baseImplementation.callData
        );
        emergencyOperator = address(0);
        emit ResetToBaseImplementation(_baseImplementation, tx.origin);
    }
}
