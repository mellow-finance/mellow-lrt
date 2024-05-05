// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/IDefaultAccessControl.sol";
import "../external/chainlink/IAggregatorV3.sol";

import "./IPriceOracle.sol";

interface IChainlinkOracle is IPriceOracle {
    error AddressZero();
    error InvalidLength();
    error Forbidden();
    error StaleOracle();

    function MAX_ORACLE_AGE() external view returns (uint256);
    function Q96() external view returns (uint256);

    function aggregatorsV3(address, address) external view returns (address);
    function baseTokens(address) external view returns (address);

    function setBaseToken(address vault, address baseToken) external;
    function setChainlinkOracles(
        address vault,
        address[] memory tokens,
        address[] memory oracles
    ) external;

    function getPrice(
        address vault,
        address token
    ) external view returns (uint256 answer, uint8 decimals);
}
