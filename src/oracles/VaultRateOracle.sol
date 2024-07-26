// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/oracles/IChainlinkOracle.sol";
import "../interfaces/IVault.sol";

contract VaultRateOracle is IAggregatorV3 {
    error InvalidBaseToken();

    uint256 private constant D18 = 1e18;
    uint256 private constant Q96 = 2 ** 96;

    uint8 public constant decimals = 18;
    uint256 public constant version = 1;

    IVault public immutable vault;
    string public description;

    constructor(IVault vault_) {
        vault = vault_;
        address baseToken_ = IChainlinkOracle(
            vault.configurator().priceOracle()
        ).baseTokens(address(vault));
        if (baseToken_ == address(0)) revert InvalidBaseToken();
        description = string.concat(
            "Vault Rate Oracle for ",
            IERC20Metadata(address(vault_)).symbol(),
            " (",
            IERC20Metadata(address(vault_)).name(),
            ")"
        );
    }

    function baseToken() external view returns (address) {
        return
            IChainlinkOracle(vault.configurator().priceOracle()).baseTokens(
                address(vault)
            );
    }

    function getRate() public view returns (uint256) {
        uint256 totalValue = 0;
        uint256 totalSupply = vault.totalSupply();
        IPriceOracle priceOracle = IPriceOracle(
            vault.configurator().priceOracle()
        );
        (address[] memory tokens, uint256[] memory amounts) = vault
            .underlyingTvl();
        for (uint256 i = 0; i < tokens.length; i++)
            totalValue += Math.mulDiv(
                amounts[i],
                priceOracle.priceX96(address(vault), tokens[i]),
                Q96
            );
        return Math.mulDiv(totalValue, D18, totalSupply);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, int256(getRate()), block.timestamp, block.timestamp, 0);
    }
}
