// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/oracles/IChainlinkOracle.sol";

import "../libraries/external/FullMath.sol";

contract ChainlinkOracle is IChainlinkOracle {
    /// @inheritdoc IChainlinkOracle
    uint256 public constant MAX_ORACLE_AGE = 2 days;
    /// @inheritdoc IChainlinkOracle
    uint256 public constant Q96 = 2 ** 96;

    /// @inheritdoc IChainlinkOracle
    mapping(address => mapping(address => address)) public aggregatorsV3;
    /// @inheritdoc IChainlinkOracle
    mapping(address => address) public baseTokens;

    /// @inheritdoc IChainlinkOracle
    function setBaseToken(address vault, address baseToken) external {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        baseTokens[vault] = baseToken;
        emit ChainlinkOracleSetBaseToken(vault, baseToken, block.timestamp);
    }

    /// @inheritdoc IChainlinkOracle
    function setChainlinkOracles(
        address vault,
        address[] memory tokens,
        address[] memory oracles
    ) external {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        if (tokens.length != oracles.length) revert InvalidLength();
        for (uint256 i = 0; i < tokens.length; i++) {
            aggregatorsV3[vault][tokens[i]] = oracles[i];
        }
        emit ChainlinkOracleSetChainlinkOracles(
            vault,
            tokens,
            oracles,
            block.timestamp
        );
    }

    /// @inheritdoc IChainlinkOracle
    function getPrice(
        address vault,
        address token
    ) public view returns (uint256 answer, uint8 decimals) {
        address aggregatorV3 = aggregatorsV3[vault][token];
        if (aggregatorV3 == address(0)) revert AddressZero();
        uint256 lastTimestamp;
        int256 signedAnswer;
        (, signedAnswer, , lastTimestamp, ) = IAggregatorV3(aggregatorV3)
            .latestRoundData();
        answer = uint256(signedAnswer);
        if (block.timestamp - MAX_ORACLE_AGE > lastTimestamp)
            revert StaleOracle();
        decimals = IAggregatorV3(aggregatorV3).decimals();
    }

    /// @inheritdoc IPriceOracle
    function priceX96(
        address vault,
        address token
    ) external view returns (uint256 priceX96_) {
        if (vault == address(0)) revert AddressZero();
        if (token == address(0)) revert AddressZero();
        address baseToken = baseTokens[vault];
        if (baseToken == address(0)) revert AddressZero();
        if (token == baseToken) return Q96;
        (uint256 tokenPrice, uint8 decimals) = getPrice(vault, token);
        (uint256 baseTokenPrice, uint8 baseDecimals) = getPrice(
            vault,
            baseToken
        );
        priceX96_ = FullMath.mulDiv(
            tokenPrice * 10 ** baseDecimals,
            Q96,
            baseTokenPrice * 10 ** decimals
        );
    }
}
