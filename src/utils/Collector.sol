// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../src/Vault.sol";
import "../../src/VaultConfigurator.sol";
import "../../src/validators/AllowAllValidator.sol";
import "../../src/validators/ManagedValidator.sol";
import "../../src/validators/DefaultBondValidator.sol";
import "../../src/validators/ERC20SwapValidator.sol";
import "../../src/utils/DefaultAccessControl.sol";
import "../../src/utils/DepositWrapper.sol";
import "../../src/strategies/SimpleDVTStakingStrategy.sol";
import "../../src/strategies/DefaultBondStrategy.sol";
import "../../src/oracles/ChainlinkOracle.sol";
import "../../src/oracles/ManagedRatiosOracle.sol";
import "../../src/modules/erc20/ERC20TvlModule.sol";
import "../../src/modules/erc20/ERC20SwapModule.sol";
import "../../src/modules/erc20/ManagedTvlModule.sol";
import "../../src/modules/obol/StakingModule.sol";

import "../../src/modules/symbiotic/DefaultBondModule.sol";
import "../../src/modules/symbiotic/DefaultBondTvlModule.sol";

import "../../src/libraries/external/FullMath.sol";

import "../../src/interfaces/external/lido/ISteth.sol";
import "../../src/interfaces/external/lido/IWSteth.sol";
import "../../src/interfaces/external/lido/IStakingRouter.sol";
import "../../src/interfaces/external/lido/IDepositContract.sol";
import "../../src/interfaces/external/uniswap/ISwapRouter.sol";

import "../../src/oracles/WStethRatiosAggregatorV3.sol";
import "../../src/oracles/ConstantAggregatorV3.sol";

contract Collector {
    struct Response {
        address vault;
        uint256 balance;
        address[] baseTokens;
        uint256[] baseAmounts;
        address[] underlyingTokens;
        uint256[] underlyingAmounts;
        uint256[] pricesX96;
        uint256 totalSupply;
        uint256 totalValue;
        uint128[] depositRatioX96;
        uint128[] withdrawalRatioX96;
        IVault.WithdrawalRequest withdrawalRequest;
    }

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 1e9;

    function collect(
        address user,
        address[] memory vaults
    ) public view returns (Response[] memory responses) {
        uint256 n = vaults.length;
        responses = new Response[](n);
        for (uint256 i = 0; i < n; i++) {
            IVault vault = IVault(vaults[i]);
            responses[i].vault = address(vault);
            responses[i].balance = vault.balanceOf(user);
            responses[i].totalSupply = vault.totalSupply();
            (responses[i].baseTokens, responses[i].baseAmounts) = vault
                .baseTvl();
            (
                responses[i].underlyingTokens,
                responses[i].underlyingAmounts
            ) = vault.underlyingTvl();

            {
                address[] memory tokens = responses[i].underlyingTokens;
                responses[i].pricesX96 = new uint256[](tokens.length);
                IPriceOracle priceOracle = IPriceOracle(
                    vault.configurator().priceOracle()
                );
                for (uint256 j = 0; j < tokens.length; j++) {
                    responses[i].pricesX96[j] = priceOracle.priceX96(
                        address(vault),
                        tokens[j]
                    );
                    responses[i].totalValue += FullMath.mulDiv(
                        responses[i].pricesX96[j],
                        responses[i].underlyingAmounts[j],
                        Q96
                    );
                }
            }

            {
                IRatiosOracle oracle = IRatiosOracle(
                    vault.configurator().ratiosOracle()
                );
                responses[i].depositRatioX96 = oracle.getTargetRatiosX96(
                    address(vault),
                    true
                );
                responses[i].withdrawalRatioX96 = oracle.getTargetRatiosX96(
                    address(vault),
                    false
                );
            }
            responses[i].withdrawalRequest = vault.withdrawalRequest(user);
        }
    }

    function fetchWithdrawalAmounts(
        uint256 lpAmount,
        address vault
    ) external view returns (uint256[] memory expectedAmounts) {
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        Response memory response = collect(address(0), vaults)[0];
        uint256 value = FullMath.mulDiv(
            lpAmount,
            response.totalValue,
            response.totalSupply
        );
        IVault.ProcessWithdrawalsStack memory s = IVault(vault)
            .calculateStack();
        value = FullMath.mulDiv(value, D9 - s.feeD9, D9);
        uint256 coefficientX96 = FullMath.mulDiv(value, Q96, s.ratiosX96Value);
        uint256 length = s.erc20Balances.length;
        expectedAmounts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 ratiosX96 = s.ratiosX96[i];
            expectedAmounts[i] = ratiosX96 == 0
                ? 0
                : FullMath.mulDiv(coefficientX96, ratiosX96, Q96);
        }
        return expectedAmounts;
    }

    function fetchDepositWrapperParams(
        address vault,
        address wrapper
    )
        external
        view
        returns (
            bool isDepositsPossible,
            bool isDepositorWhitelisted,
            uint256 lpPriceX96
        )
    {
        if (IVault(vault).configurator().isDepositsLocked())
            return (false, false, 0);
        {
            IValidator validator = IValidator(
                IVault(vault).configurator().validator()
            );
            try
                validator.validate(
                    wrapper,
                    vault,
                    abi.encodeWithSelector(IVault.deposit.selector)
                )
            {
                isDepositorWhitelisted = true;
            } catch {
                isDepositorWhitelisted = false;
                return (true, false, 0);
            }
        }
        isDepositsPossible = true;
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        Response memory response = collect(address(0), vaults)[0];
        uint256 totalValue = response.totalValue;
        lpPriceX96 = FullMath.mulDiv(totalValue, Q96, response.totalSupply);
    }

    function fetchDepositAmounts(
        uint256[] memory amounts,
        address vault,
        address user
    )
        external
        view
        returns (
            bool isDepositsPossible,
            bool isDepositorWhitelisted,
            address[] memory tokens,
            uint256 expectedLpAmount,
            uint256[] memory expectedAmounts
        )
    {
        if (IVault(vault).configurator().isDepositsLocked())
            return (false, false, new address[](0), 0, new uint256[](0));
        {
            IValidator validator = IValidator(
                IVault(vault).configurator().validator()
            );
            try
                validator.validate(
                    user,
                    vault,
                    abi.encodeWithSelector(IVault.deposit.selector)
                )
            {
                isDepositorWhitelisted = true;
            } catch {
                isDepositorWhitelisted = false;
                return (true, false, new address[](0), 0, new uint256[](0));
            }
        }

        isDepositsPossible = true;
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        Response memory response = collect(address(0), vaults)[0];

        tokens = response.underlyingTokens;
        uint256 ratioX96 = type(uint256).max;
        uint128[] memory ratiosX96 = response.depositRatioX96;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (ratiosX96[i] == 0) continue;
            uint256 ratioX96_ = FullMath.mulDiv(amounts[i], Q96, ratiosX96[i]);
            if (ratioX96_ < ratioX96) ratioX96 = ratioX96_;
        }
        if (ratioX96 == 0)
            return (false, false, tokens, 0, new uint256[](tokens.length));
        uint256 depositValue = 0;
        uint256 totalValue = 0;
        expectedAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 priceX96 = response.pricesX96[i];
            totalValue += response.underlyingAmounts[i] == 0
                ? 0
                : FullMath.mulDivRoundingUp(
                    response.underlyingAmounts[i],
                    priceX96,
                    Q96
                );
            if (ratiosX96[i] == 0) continue;
            uint256 amount = FullMath.mulDiv(ratioX96, ratiosX96[i], Q96);
            expectedAmounts[i] = amount;
            depositValue += FullMath.mulDiv(amount, priceX96, Q96);
        }
        expectedLpAmount = FullMath.mulDiv(
            depositValue,
            response.totalSupply,
            totalValue
        );
    }

    function test() external pure {}
}
