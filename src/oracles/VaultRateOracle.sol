// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/external/chainlink/IAggregatorV3.sol";
import "../interfaces/oracles/IChainlinkOracle.sol";

import "../interfaces/IVault.sol";

contract VaultRateOracle is IAggregatorV3 {
    uint256 public constant D18 = 1e18;

    uint8 public constant decimals = 18;
    uint256 public constant version = 1;

    IVault public immutable vault;
    string public description;

    constructor(IVault vault_) {
        vault = vault_;
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

    function fetchParams()
        public
        view
        returns (uint256 totalValue, uint256 totalSupply)
    {
        IVault.ProcessWithdrawalsStack memory stack = vault.calculateStack();
        totalValue = stack.totalValue;
        totalSupply = stack.totalSupply;
    }

    function getRate() public view returns (uint256) {
        (uint256 totalValue, uint256 totalSupply) = fetchParams();
        return Math.mulDiv(totalValue, D18, totalSupply);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 0;
        answer = int256(getRate());
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 0;
    }
}
