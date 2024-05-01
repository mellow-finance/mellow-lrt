// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../utils/IDepositCallback.sol";

import "../modules/erc20/IERC20TvlModule.sol";
import "../modules/symbiotic/IDefaultBondModule.sol";

interface IDefaultBondStrategy is IDepositCallback {
    error InvalidCumulativeRatio();

    struct Data {
        address bond;
        uint256 ratioX96;
    }

    function Q96() external view returns (uint256);
    function vault() external view returns (IVault);
    function erc20TvlModule() external view returns (IERC20TvlModule);
    function bondModule() external view returns (IDefaultBondModule);

    function tokenToData(address) external view returns (bytes memory);

    function setData(address token, Data[] memory data) external;

    function processAll() external;

    function processWithdrawals(address[] memory users) external;
}
