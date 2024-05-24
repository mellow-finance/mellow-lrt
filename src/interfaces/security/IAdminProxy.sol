// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IAdminProxy {
    error Forbidden();

    function proxy() external view returns (ITransparentUpgradeableProxy);

    function baseImplementation() external view returns (address);

    function proposer() external view returns (address);

    function acceptor() external view returns (address);

    function proposedImplementationAt(
        uint256 index
    ) external view returns (address);

    function proposedImplementationsCount() external view returns (uint256);

    function setProposer(address newProposer) external;

    function upgradeProposer(address newProposer) external;

    function upgradeAcceptor(address newAcceptor) external;

    function proposeImplementation(address implementation) external;

    function cancelImplementation(address implementation) external;

    function acceptImplementation(address implementation) external;

    function rejectImplementation(address implementation) external;

    function resetToBaseImplementation() external;
}
