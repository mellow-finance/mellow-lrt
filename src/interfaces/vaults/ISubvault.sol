// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./IRootVault.sol";

interface ISubvault is IERC165 {
    error NotAuthorized();

    function rootVault() external view returns (IRootVault);

    function push(
        uint256[] memory tokenAmounts
    ) external returns (uint256[] memory actualTokenAmounts);

    function pull(
        address to,
        uint256[] memory amounts
    ) external returns (uint256[] memory actualTokenAmounts);

    function externalCall(
        address to,
        bytes memory data
    ) external returns (bool success, bytes memory response);

    function tvl() external view returns (uint256[] memory amounts);

    function addToken(address token) external;

    function removeToken(address token) external;
}
