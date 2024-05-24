// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AdminProxy {
    error Forbidden();

    using EnumerableSet for EnumerableSet.AddressSet;

    ITransparentUpgradeableProxy public immutable proxy;
    address public immutable admin;
    address public immutable baseImplementation;

    address public proposer;
    address public acceptor;

    EnumerableSet.AddressSet private _implementations;

    constructor(
        address proxy_,
        address admin_,
        address proposer_,
        address acceptor_,
        address baseImplementation_
    ) {
        proxy = ITransparentUpgradeableProxy(proxy_);
        admin = admin_;
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

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Forbidden();
        _;
    }

    function proposedImplementationAt(
        uint256 index
    ) external view returns (address) {
        return _implementations.at(index);
    }

    function proposeImplementationsCount() external view returns (uint256) {
        return _implementations.length();
    }

    function upgradeProposer(address newProposer) external onlyProposer {
        proposer = newProposer;
    }

    function upgradeAcceptor(address newAcceptor) external onlyAcceptor {
        acceptor = newAcceptor;
    }

    function proposeImplementation(
        address implementation
    ) external onlyProposer {
        _implementations.add(implementation);
    }

    function cancelImplementation(
        address implementation
    ) external onlyProposer {
        _implementations.remove(implementation);
    }

    function acceptImplementation(
        address implementation
    ) external onlyAcceptor {
        if (!_implementations.contains(implementation)) revert Forbidden();
        proxy.upgradeToAndCall(implementation, new bytes(0));
        _implementations.remove(implementation);
    }

    function rejectImplementation(
        address implementation
    ) external onlyAcceptor {
        if (!_implementations.contains(implementation)) revert Forbidden();
        _implementations.remove(implementation);
    }

    function resetToBaseImplementation() external onlyProposer {
        proxy.upgradeToAndCall(baseImplementation, new bytes(0));
        proposer = address(0);
    }

    function setProposer(address proposer_) external onlyAdmin {
        proposer = proposer_;
    }

    function setAcceptor(address acceptor_) external onlyAdmin {
        acceptor = acceptor_;
    }
}
