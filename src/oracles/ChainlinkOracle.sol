// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/oracles/IOracle.sol";
import "../interfaces/external/chainlink/IAggregatorV3.sol";

import "../libraries/external/FullMath.sol";

import "../utils/DefaultAccessControl.sol";

contract ChainlinkOracle is IOracle, DefaultAccessControl {
    address public immutable baseToken;

    uint256 public constant MAX_ORACLE_AGE = 2 days;
    uint256 public constant Q96 = 2 ** 96;

    mapping(address => address) public oracles;

    constructor(address admin, address baseToken_) DefaultAccessControl(admin) {
        baseToken = baseToken_;
    }

    function addChainlinkOracles(
        address[] memory tokens_,
        address[] memory oracles_
    ) external {
        _requireAdmin();
        if (tokens_.length != oracles_.length)
            revert("ChainlinkOracle: Invalid length");

        for (uint256 i = 0; i < tokens_.length; i++) {
            oracles[tokens_[i]] = oracles_[i];
        }
    }

    function getPrice(
        address token
    ) public view returns (uint256 answer, uint8 decimals) {
        address oracle = oracles[token];
        if (oracle == address(0)) revert("ChainlinkOracle: Invalid oracle");
        uint256 lastTimestamp;

        int256 signedAnswer;
        (, signedAnswer, , lastTimestamp, ) = IAggregatorV3(oracle)
            .latestRoundData();
        answer = uint256(signedAnswer);
        if (block.timestamp - MAX_ORACLE_AGE > lastTimestamp)
            revert("ChainlinkOracle: Stale oracle");
        decimals = IAggregatorV3(oracle).decimals();
    }

    function priceX96(address token) external view returns (uint256 priceX96_) {
        (uint256 tokenPrice, uint8 decimals) = getPrice(token);
        (uint256 baseTokenPrice, uint8 baseDecimals) = getPrice(baseToken);
        priceX96_ = FullMath.mulDiv(
            tokenPrice * 10 ** baseDecimals,
            Q96,
            baseTokenPrice * 10 ** decimals
        );
    }
}
