// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "../interfaces/oracles/IChainlinkOracle.sol";

import "../libraries/external/FullMath.sol";

contract ChainlinkOracle is IChainlinkOracle {
    /// @inheritdoc IChainlinkOracle
    uint256 public constant Q96 = 2 ** 96;

    /// @inheritdoc IChainlinkOracle
    mapping(address => address) public baseTokens;

    mapping(address => mapping(address => AggregatorData))
        private _aggregatorsData;

    /// @inheritdoc IChainlinkOracle
    function aggregatorsData(
        address vault,
        address token
    ) external view returns (AggregatorData memory) {
        return _aggregatorsData[vault][token];
    }

    /// @inheritdoc IChainlinkOracle
    function setBaseToken(address vault, address baseToken) external {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        baseTokens[vault] = baseToken;
        emit ChainlinkOracleSetBaseToken(vault, baseToken, block.timestamp);
    }

    /// @inheritdoc IChainlinkOracle
    function setChainlinkOracles(
        address vault,
        address[] calldata tokens,
        AggregatorData[] calldata data_
    ) external {
        IDefaultAccessControl(vault).requireAdmin(msg.sender);
        if (tokens.length != data_.length) revert InvalidLength();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (data_[i].aggregatorV3 == address(0)) continue;
            _validateAndGetPrice(data_[i]);
        }
        for (uint256 i = 0; i < tokens.length; i++) {
            _aggregatorsData[vault][tokens[i]] = data_[i];
        }
        emit ChainlinkOracleSetChainlinkOracles(
            vault,
            tokens,
            data_,
            block.timestamp
        );
    }

    function _validateAndGetPrice(
        AggregatorData memory data
    ) private view returns (uint256 answer, uint8 decimals) {
        if (data.aggregatorV3 == address(0)) revert AddressZero();
        (, int256 signedAnswer, , uint256 lastTimestamp, ) = IAggregatorV3(
            data.aggregatorV3
        ).latestRoundData();
        // The roundId and latestRound are not used in the validation process to ensure compatibility
        // with various custom aggregator implementations that may handle these parameters differently
        if (signedAnswer < 0) revert InvalidOracleData();
        answer = uint256(signedAnswer);
        if (block.timestamp - data.maxAge > lastTimestamp) revert StaleOracle();
        decimals = IAggregatorV3(data.aggregatorV3).decimals();
    }

    /// @inheritdoc IChainlinkOracle
    function getPrice(
        address vault,
        address token
    ) public view returns (uint256 answer, uint8 decimals) {
        return _validateAndGetPrice(_aggregatorsData[vault][token]);
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

        uint8 totalTokenDecimals = decimals + IERC20Metadata(token).decimals();
        uint8 totalBaseTokenDecimals = baseDecimals +
            IERC20Metadata(baseToken).decimals();

        if (totalTokenDecimals < totalBaseTokenDecimals) {
            priceX96_ = FullMath.mulDiv(
                tokenPrice *
                    10 ** (totalBaseTokenDecimals - totalTokenDecimals),
                Q96,
                baseTokenPrice
            );
        } else {
            priceX96_ = FullMath.mulDiv(
                tokenPrice,
                Q96,
                baseTokenPrice *
                    10 ** (totalTokenDecimals - totalBaseTokenDecimals)
            );
        }
    }
}
