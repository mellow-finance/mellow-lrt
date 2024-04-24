// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ISubvault.sol";

import "../utils/IDefaultAccessControl.sol";
import "../oracles/IOracle.sol";
import "../oracles/IRatiosOracle.sol";

interface IRootVault is IDefaultAccessControl {
    error AlreadyInitialized();
    error InvalidLength();
    error InvalidSubvault();
    error InvalidAddress();
    error InvalidValue();

    function D9() external view returns (uint256);
    function Q96() external view returns (uint256);
    function oracle() external view returns (IOracle);
    function ratiosOracle() external view returns (IRatiosOracle);
    function validator() external view returns (address);
    function withdrawalFeeD9() external view returns (uint256);

    function initialize(
        address[] memory subvaults_,
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256 initialTotalSupply_
    ) external;

    function subvaultCount() external view returns (uint256);
    function subvaultAt(uint256 index) external view returns (address);

    function hasSubvault(address vault) external view returns (bool);
    function deposit(
        uint256[] memory amounts,
        uint256 minLpAmount
    ) external returns (uint256 lpAmount, uint256[] memory actualTokenAmounts);
    function withdraw(
        uint256 lpAmount,
        uint256[] memory minTokenAmounts
    )
        external
        returns (uint256 actualLpAmount, uint256[] memory actualTokenAmounts);

    function tvl() external view returns (uint256[] memory amounts);

    function tokens() external view returns (address[] memory);

    function addToken(address token) external;

    function removeToken(address token) external;
}
