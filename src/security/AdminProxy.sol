// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/security/IAdminProxy.sol";

contract AdminProxy is IAdminProxy {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IAdminProxy
    ITransparentUpgradeableProxy public immutable proxy;
    /// @inheritdoc IAdminProxy
    address public immutable baseImplementation;

    /// @inheritdoc IAdminProxy
    address public proposer;
    /// @inheritdoc IAdminProxy
    address public acceptor;

    EnumerableSet.AddressSet private _implementations;

    constructor(
        address proxy_,
        address proposer_,
        address acceptor_,
        address baseImplementation_
    ) {
        proxy = ITransparentUpgradeableProxy(proxy_);
        proposer = proposer_;
        acceptor = acceptor_;
        baseImplementation = baseImplementation_;
    }

    modifier onlyProposer() {
        if (msg.sender != proposer) revert Forbidden();
        _;
    }

    modifier onlyAcceptor() {
        if (msg.sender != acceptor) revert Forbidden();
        _;
    }

    /// @inheritdoc IAdminProxy
    function proposedImplementationAt(
        uint256 index
    ) external view returns (address) {
        return _implementations.at(index);
    }

    /// @inheritdoc IAdminProxy
    function proposedImplementationsCount() external view returns (uint256) {
        return _implementations.length();
    }

    /// @inheritdoc IAdminProxy
    function setProposer(address newProposer) external onlyAcceptor {
        if (proposer != address(0)) revert Forbidden();
        proposer = newProposer;
    }

    /// @inheritdoc IAdminProxy
    function upgradeProposer(address newProposer) external onlyProposer {
        proposer = newProposer;
    }

    /// @inheritdoc IAdminProxy
    function upgradeAcceptor(address newAcceptor) external onlyAcceptor {
        acceptor = newAcceptor;
    }

    /// @inheritdoc IAdminProxy
    function proposeImplementation(
        address implementation
    ) external onlyProposer {
        _implementations.add(implementation);
    }

    /// @inheritdoc IAdminProxy
    function cancelImplementation(
        address implementation
    ) external onlyProposer {
        _implementations.remove(implementation);
    }

    /// @inheritdoc IAdminProxy
    function acceptImplementation(
        address implementation
    ) external onlyAcceptor {
        if (!_implementations.contains(implementation)) revert Forbidden();
        proxy.upgradeToAndCall(implementation, new bytes(0));
        _implementations.remove(implementation);
    }

    /// @inheritdoc IAdminProxy
    function rejectImplementation(
        address implementation
    ) external onlyAcceptor {
        if (!_implementations.contains(implementation)) revert Forbidden();
        _implementations.remove(implementation);
    }

    /// @inheritdoc IAdminProxy
    function resetToBaseImplementation() external onlyProposer {
        proxy.upgradeToAndCall(baseImplementation, new bytes(0));
        proposer = address(0);
    }
}
