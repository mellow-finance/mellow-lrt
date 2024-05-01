// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/oracles/IPriceOracle.sol";
import "../interfaces/external/chainlink/IAggregatorV3.sol";

import "../libraries/external/FullMath.sol";

import "../utils/DefaultAccessControl.sol";

contract ChainlinkOracle is IPriceOracle, DefaultAccessControl {
    /// mb mutable?
    address public immutable baseToken;

    uint256 public constant MAX_ORACLE_AGE = 2 days;
    uint256 public constant Q96 = 2 ** 96;

    mapping(address => address) public aggregatorsV3;

    constructor(address admin, address baseToken_) DefaultAccessControl(admin) {
        baseToken = baseToken_;
    }

    function setChainlinkOracles(
        address[] memory tokens_,
        address[] memory oracles_
    ) external {
        _requireAdmin();
        if (tokens_.length != oracles_.length)
            revert("ChainlinkOracle: invalid length");
        for (uint256 i = 0; i < tokens_.length; i++) {
            aggregatorsV3[tokens_[i]] = oracles_[i];
        }
    }

    function getPrice(
        address token
    ) public view returns (uint256 answer, uint8 decimals) {
        address aggregatorV3 = aggregatorsV3[token];
        if (aggregatorV3 == address(0))
            revert("ChainlinkOracle: aggregator not found");
        uint256 lastTimestamp;

        int256 signedAnswer;
        (, signedAnswer, , lastTimestamp, ) = IAggregatorV3(aggregatorV3)
            .latestRoundData();
        answer = uint256(signedAnswer);
        if (block.timestamp - MAX_ORACLE_AGE > lastTimestamp)
            revert("ChainlinkOracle: stale price feed");
        decimals = IAggregatorV3(aggregatorV3).decimals();
    }

    /*
        chainlink prices:
        basePrice = X
        token1Price = y1
        token2Price = y2

        oracle price:
        token1price = y1 / x
        token2price = y2 / x
        token3price = 1

        // TODO: fix problem with eth/usd oracles
    */

    function priceX96(address token) external view returns (uint256 priceX96_) {
        if (token == baseToken) return Q96;
        (uint256 tokenPrice, uint8 decimals) = getPrice(token);
        (uint256 baseTokenPrice, uint8 baseDecimals) = getPrice(baseToken);
        priceX96_ = FullMath.mulDiv(
            tokenPrice * 10 ** baseDecimals,
            Q96,
            baseTokenPrice * 10 ** decimals
        );
    }
}
