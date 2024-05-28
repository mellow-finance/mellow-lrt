// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title IAdminProxy Interface
 * @dev This interface defines the structure and functions of the AdminProxy contract.
 * It includes error definitions, struct definitions, function signatures, and event declarations.
 */
interface IAdminProxy {
    /**
     * @dev Custom error to indicate forbidden actions.
     */
    error Forbidden();

    /**
     * @dev Structure to represent a proposal.
     * @param implementation The address of the implementation contract.
     * @param callData The calldata to be sent to the implementation contract when the proposal is accepted.
     */
    struct Proposal {
        address implementation;
        bytes callData;
    }

    /**
     * @dev Returns the address of the proxy contract.
     * @return The proxy contract address.
     */
    function proxy() external view returns (ITransparentUpgradeableProxy);

    /**
     * @dev Returns the address of the proxy admin contract.
     * @return The proxy admin contract address.
     */
    function proxyAdmin() external view returns (ProxyAdmin);

    /**
     * @dev Returns the current base implementation.
     * @return The current base implementation proposal.
     */
    function baseImplementation() external view returns (Proposal memory);

    /**
     * @dev Returns the currently proposed base implementation.
     * @return The proposed base implementation proposal.
     */
    function proposedBaseImplementation()
        external
        view
        returns (Proposal memory);

    /**
     * @dev Returns the address of the current proposer.
     * @return The proposer address.
     */
    function proposer() external view returns (address);

    /**
     * @dev Returns the address of the current acceptor.
     * @return The acceptor address.
     */
    function acceptor() external view returns (address);

    /**
     * @dev Returns the address of the emergency operator.
     * @return The emergency operator address.
     */
    function emergencyOperator() external view returns (address);

    /**
     * @dev Returns the proposal at the specified index.
     * @param index The index of the proposal to retrieve.
     * @return The proposal at the given index.
     */
    function proposalAt(uint256 index) external view returns (Proposal memory);

    /**
     * @dev Returns the total number of proposals.
     * @return The number of proposals.
     */
    function proposalsCount() external view returns (uint256);

    /**
     * @dev Returns the latest accepted nonce.
     * @return The latest accepted nonce.
     */
    function latestAcceptedNonce() external view returns (uint256);

    /**
     * @dev Function to upgrade the proposer to a new address.
     * This can only be called by the acceptor.
     * @param newProposer The address of the new proposer.
     */
    function upgradeProposer(address newProposer) external;

    /**
     * @dev Function to upgrade the acceptor to a new address.
     * This can only be called by the current acceptor.
     * @param newAcceptor The address of the new acceptor.
     */
    function upgradeAcceptor(address newAcceptor) external;

    /**
     * @dev Function to upgrade the emergency operator to a new address.
     * This can only be called by the acceptor.
     * @param newEmergencyOperator The address of the new emergency operator.
     */
    function upgradeEmergencyOperator(address newEmergencyOperator) external;

    /**
     * @dev Function to propose a new implementation.
     * This can be called by the proposer or the acceptor.
     * @param implementation The address of the proposed implementation contract.
     * @param callData The calldata to be sent to the proposed implementation contract.
     */
    function propose(address implementation, bytes calldata callData) external;

    /**
     * @dev Function to propose a new base implementation.
     * This can be called by the proposer or the acceptor.
     * @param implementation The address of the proposed base implementation contract.
     * @param callData The calldata to be sent to the proposed base implementation contract.
     */
    function proposeBaseImplementation(
        address implementation,
        bytes calldata callData
    ) external;

    /**
     * @dev Function to accept the proposed base implementation.
     * This can only be called by the acceptor.
     * The proposed base implementation is set as the new base implementation.
     */
    function acceptBaseImplementation() external;

    /**
     * @dev Function to accept a proposal at the specified index.
     * This can only be called by the acceptor.
     * The proxy is upgraded to the implementation specified in the accepted proposal.
     * @param index The index of the proposal to accept.
     */
    function acceptProposal(uint256 index) external;

    /**
     * @dev Function to reject all proposals.
     * This can only be called by the acceptor.
     * All existing proposals are rejected by setting the latest accepted nonce to the length of the proposals array.
     */
    function rejectAllProposals() external;

    /**
     * @dev Function to reset to the base implementation.
     * This can only be called by the emergency operator.
     * The proxy is reset to the base implementation, and the emergency operator address is cleared.
     */
    function resetToBaseImplementation() external;

    /**
     * @dev Emitted when the emergency operator is upgraded.
     * @param newEmergencyOperator The address of the new emergency operator.
     * @param origin The address that initiated the upgrade.
     */
    event EmergencyOperatorUpgraded(
        address newEmergencyOperator,
        address origin
    );

    /**
     * @dev Emitted when the proposer is upgraded.
     * @param newProposer The address of the new proposer.
     * @param origin The address that initiated the upgrade.
     */
    event ProposerUpgraded(address newProposer, address origin);

    /**
     * @dev Emitted when the acceptor is upgraded.
     * @param newAcceptor The address of the new acceptor.
     * @param origin The address that initiated the upgrade.
     */
    event AcceptorUpgraded(address newAcceptor, address origin);

    /**
     * @dev Emitted when a proposal is accepted.
     * @param index The index of the accepted proposal.
     * @param origin The address that accepted the proposal.
     */
    event ProposalAccepted(uint256 index, address origin);

    /**
     * @dev Emitted when all proposals are rejected.
     * @param latestAcceptedNonce The nonce of the latest accepted proposal.
     * @param origin The address that rejected all proposals.
     */
    event AllProposalsRejected(uint256 latestAcceptedNonce, address origin);

    /**
     * @dev Emitted when the proxy is reset to the base implementation.
     * @param implementation The base implementation to which the proxy was reset.
     * @param origin The address that initiated the reset.
     */
    event ResetToBaseImplementation(Proposal implementation, address origin);

    /**
     * @dev Emitted when a new implementation is proposed.
     * @param implementation The address of the proposed implementation.
     * @param callData The calldata for the proposed implementation.
     * @param origin The address that proposed the implementation.
     */
    event ImplementationProposed(
        address implementation,
        bytes callData,
        address origin
    );

    /**
     * @dev Emitted when a new base implementation is proposed.
     * @param implementation The proposed base implementation.
     * @param origin The address that proposed the base implementation.
     */
    event BaseImplementationProposed(Proposal implementation, address origin);

    /**
     * @dev Emitted when the proposed base implementation is accepted.
     * @param implementation The accepted base implementation.
     * @param origin The address that accepted the base implementation.
     */
    event BaseImplementationAccepted(Proposal implementation, address origin);
}
