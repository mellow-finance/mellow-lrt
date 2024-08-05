// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

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

import "../../src/interfaces/external/lido/ISteth.sol";
import "../../src/interfaces/external/lido/IWSteth.sol";
import "../../src/interfaces/external/lido/IStakingRouter.sol";
import "../../src/interfaces/external/lido/IDepositContract.sol";
import "../../src/interfaces/external/uniswap/ISwapRouter.sol";

import "../../src/oracles/WStethRatiosAggregatorV3.sol";
import "../../src/oracles/ConstantAggregatorV3.sol";

import "./IDefiCollector.sol";

contract Collector is DefaultAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Response {
        address vault;
        uint256 balance; // Vault.balanceOf(user)
        address[] underlyingTokens; // deposit/withdrawal tokens
        uint256[] underlyingAmounts; // their amounts
        uint8[] underlyingTokenDecimals; // their decimals
        uint128[] depositRatiosX96; // ratiosX96 for deposits
        uint128[] withdrawalRatiosX96; // ratiosX96 for withdrawals
        uint256[] pricesX96; // pricesX96 for underlying tokens
        uint256 totalSupply; // total supply of the vault
        uint256 userBalanceETH; // user vault balance in ETH
        uint256 userBalanceUSDC; // user vault balance in USDC
        uint256 totalValueETH; // total value of the vault in ETH
        uint256 totalValueUSDC; // total value of the vault in USDC
        uint256 lpPriceD18; // LP price in USDC weis 1e8 (due to chainlink decimals)
        bool shouldCloseWithdrawalRequest; // if the withdrawal request should be closed
        IVault.WithdrawalRequest withdrawalRequest; // withdrawal request
        bool isDefi; // if the vault address is an address of some DeFi pool
    }

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 1e9;
    uint256 public constant D18 = 1e18;

    address public immutable wsteth;
    address public immutable weth;
    address public immutable steth;

    IAggregatorV3 public immutable wstethOracle;
    IAggregatorV3 public immutable wethOracle;

    EnumerableSet.AddressSet private collectors_;

    constructor(
        address wsteth_,
        address weth_,
        address steth_,
        IAggregatorV3 _wstethOracle,
        IAggregatorV3 _wethToUSDOracle,
        address admin_
    ) DefaultAccessControl(admin_) {
        wsteth = wsteth_;
        weth = weth_;
        steth = steth_;
        wstethOracle = _wstethOracle;
        wethOracle = _wethToUSDOracle;
    }

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
            (
                responses[i].underlyingTokens,
                responses[i].underlyingAmounts
            ) = vault.underlyingTvl();

            {
                IPriceOracle oracle = IPriceOracle(
                    vault.configurator().priceOracle()
                );
                responses[i].pricesX96 = new uint256[](
                    responses[i].underlyingTokens.length
                );
                responses[i].underlyingTokenDecimals = new uint8[](
                    responses[i].underlyingTokens.length
                );
                for (
                    uint256 j = 0;
                    j < responses[i].underlyingTokens.length;
                    j++
                ) {
                    responses[i].pricesX96[j] = oracle.priceX96(
                        address(vault),
                        responses[i].underlyingTokens[j]
                    );
                    responses[i].underlyingTokenDecimals[j] = IERC20Metadata(
                        responses[i].underlyingTokens[j]
                    ).decimals();
                    responses[i].totalValueETH += FullMath.mulDiv(
                        responses[i].pricesX96[j],
                        responses[i].underlyingAmounts[j],
                        Q96
                    );
                }
                responses[i].totalValueUSDC = convertWethToUSDC(
                    responses[i].totalValueETH
                );
                responses[i].userBalanceETH = FullMath.mulDiv(
                    responses[i].totalValueETH,
                    responses[i].balance,
                    vault.totalSupply()
                );
                responses[i].userBalanceUSDC = convertWethToUSDC(
                    responses[i].userBalanceETH
                );
                responses[i].lpPriceD18 = FullMath.mulDiv(
                    responses[i].totalValueUSDC,
                    D18,
                    responses[i].totalSupply
                );
            }

            {
                IRatiosOracle oracle = IRatiosOracle(
                    vault.configurator().ratiosOracle()
                );
                responses[i].depositRatiosX96 = oracle.getTargetRatiosX96(
                    address(vault),
                    true
                );

                responses[i].withdrawalRatiosX96 = oracle.getTargetRatiosX96(
                    address(vault),
                    false
                );
            }

            (bool isProcessingPossible, , ) = vault.analyzeRequest(
                vault.calculateStack(),
                vault.withdrawalRequest(user)
            );
            responses[i].shouldCloseWithdrawalRequest = !isProcessingPossible;
            responses[i].withdrawalRequest = vault.withdrawalRequest(user);
            responses[i].balance += responses[i].withdrawalRequest.lpAmount;
        }

        return mergeWithDefiCollectors(user, vaults, responses);
    }

    function multiCollect(
        address[] memory users,
        address[] memory vaults
    ) external view returns (Response[][] memory responses) {
        responses = new Response[][](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            responses[i] = collect(users[i], vaults);
        }
    }

    function fetchWithdrawalAmounts(
        uint256 lpAmount,
        address vault
    )
        external
        view
        returns (
            uint256[] memory expectedAmounts,
            uint256[] memory expectedAmountsUSDC
        )
    {
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        Response memory response = collect(address(0), vaults)[0];
        uint256 value = FullMath.mulDiv(
            lpAmount,
            response.totalValueETH,
            response.totalSupply
        );
        IVault.ProcessWithdrawalsStack memory s = IVault(vault)
            .calculateStack();
        value = FullMath.mulDiv(value, D9 - s.feeD9, D9);
        uint256 coefficientX96 = FullMath.mulDiv(value, Q96, s.ratiosX96Value);
        uint256 length = s.erc20Balances.length;
        expectedAmounts = new uint256[](length);
        expectedAmountsUSDC = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 ratiosX96 = s.ratiosX96[i];
            expectedAmounts[i] = ratiosX96 == 0
                ? 0
                : FullMath.mulDiv(coefficientX96, ratiosX96, Q96);
            expectedAmountsUSDC[i] = convertWethToUSDC(
                FullMath.mulDiv(expectedAmounts[i], response.pricesX96[i], Q96)
            );
        }
    }

    function convertWethToUSDC(uint256 amount) public view returns (uint256) {
        (, int256 sAnswer, , , ) = wethOracle.latestRoundData();
        uint256 answer = uint256(sAnswer);
        return FullMath.mulDiv(amount, answer, D18);
    }

    function fetchDepositWrapperParams(
        address vault,
        address wrapper,
        address token,
        uint256 amount
    )
        external
        view
        returns (
            bool isDepositPossible,
            bool isDepositorWhitelisted,
            bool isWhitelistedToken,
            uint256 lpAmount, // in weis (1e18)
            uint256 depositValueUSDC // in USD weis 1e8 (due to chainlink decimals)
        )
    {
        if (IVault(vault).configurator().isDepositLocked())
            return (false, false, false, 0, 0);
        isDepositPossible = true;
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
                return (true, false, false, 0, 0);
            }
        }
        uint256 depositValue = amount;
        if (token == wsteth) {
            (, int256 sAnswer, , , ) = wstethOracle.latestRoundData();
            uint256 answer = uint256(sAnswer);
            depositValue = FullMath.mulDiv(depositValue, answer, D18);
        } else {
            if (token != address(0) && token != weth && token != steth) {
                return (true, true, false, 0, 0);
            }
        }
        isWhitelistedToken = true;
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        Response memory response = collect(address(0), vaults)[0];
        uint256 totalValue = response.totalValueETH;
        lpAmount = FullMath.mulDiv(
            depositValue,
            response.totalSupply,
            totalValue
        );
        depositValueUSDC = convertWethToUSDC(depositValue);
    }

    struct FetchDepositAmountsResponse {
        bool isDepositPossible;
        bool isDepositorWhitelisted;
        uint256[] ratiosD18; // multiplied by 1e18 for weis of underlying tokens
        address[] tokens;
        uint256 expectedLpAmount; // in lp weis 1e18
        uint256 expectedLpAmountUSDC; // in USDC weis 1e8 (due to chainlink decimals)
        uint256[] expectedAmounts; // in underlying tokens weis
        uint256[] expectedAmountsUSDC; // in USDC weis 1e8 (due to chainlink decimals)
    }

    function fetchDepositAmounts(
        uint256[] memory amounts,
        address vault,
        address user
    ) external view returns (FetchDepositAmountsResponse memory r) {
        if (IVault(vault).configurator().isDepositLocked()) return r;
        r.isDepositPossible = true;
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
                r.isDepositorWhitelisted = true;
            } catch {
                return r;
            }
        }
        address[] memory vaults = new address[](1);
        vaults[0] = vault;
        Response memory response = collect(address(0), vaults)[0];
        r.tokens = response.underlyingTokens;
        uint256 coefficientX96 = type(uint256).max;
        uint128[] memory ratiosX96 = response.depositRatiosX96;
        r.ratiosD18 = new uint256[](ratiosX96.length);
        for (uint256 i = 0; i < r.tokens.length; i++) {
            if (ratiosX96[i] == 0) continue;
            r.ratiosD18[i] = FullMath.mulDiv(ratiosX96[i], D18, Q96);
            uint256 currentCoefficientX96 = FullMath.mulDiv(
                amounts[i],
                Q96,
                ratiosX96[i]
            );
            if (currentCoefficientX96 < coefficientX96)
                coefficientX96 = currentCoefficientX96;
        }
        if (coefficientX96 == 0) return r;
        {
            uint256 depositValue = 0;
            uint256 totalValue = 0;
            r.expectedAmounts = new uint256[](r.tokens.length);
            for (uint256 i = 0; i < r.tokens.length; i++) {
                uint256 priceX96 = response.pricesX96[i];
                totalValue += response.underlyingAmounts[i] == 0
                    ? 0
                    : FullMath.mulDivRoundingUp(
                        response.underlyingAmounts[i],
                        priceX96,
                        Q96
                    );
                if (ratiosX96[i] == 0) continue;
                uint256 amount = FullMath.mulDiv(
                    coefficientX96,
                    ratiosX96[i],
                    Q96
                );
                r.expectedAmounts[i] = amount;
                depositValue += FullMath.mulDiv(amount, priceX96, Q96);
            }
            r.expectedLpAmount = FullMath.mulDiv(
                depositValue,
                response.totalSupply,
                totalValue
            );
            r.expectedLpAmountUSDC = convertWethToUSDC(depositValue);
            r.expectedAmountsUSDC = new uint256[](r.tokens.length);
            for (uint256 i = 0; i < r.tokens.length; i++) {
                r.expectedAmountsUSDC[i] = convertWethToUSDC(
                    FullMath.mulDiv(
                        r.expectedAmounts[i],
                        response.pricesX96[i],
                        Q96
                    )
                );
            }
        }
    }

    function addCollectors(address collector_) external {
        _requireAdmin();
        collectors_.add(collector_);
    }

    function removeCollector() external {
        _requireAdmin();
        collectors_.remove(msg.sender);
    }

    function isOneOf(address x, address[] memory a) public pure returns (bool) {
        for (uint256 i = 0; i < a.length; i++) if (a[i] == x) return true;
        return false;
    }

    function haveCommon(
        address[] memory a,
        address[] memory b
    ) public pure returns (bool) {
        for (uint256 i = 0; i < a.length; i++)
            if (isOneOf(a[i], b)) return true;
        return false;
    }

    function mergeWithDefiCollectors(
        address user,
        address[] memory vaults,
        Response[] memory responses
    ) public view returns (Response[] memory fullResponses) {
        address[] memory collectors = collectors_.values();
        fullResponses = new Response[](1 << 10);
        uint256 itr = 0;
        while (itr < responses.length) {
            fullResponses[itr] = responses[itr];
            itr++;
        }
        address[] memory users = new address[](1);
        users[0] = user;
        for (uint256 i = 0; i < collectors.length; i++) {
            IDefiCollector.Data[] memory data = IDefiCollector(collectors[i])
                .collect(users);

            for (uint256 j = 0; j < data.length; j++) {
                IERC20[] memory tokens = data[j].tokens;
                address[] memory tokens_ = new address[](tokens.length);
                for (uint256 k = 0; k < tokens.length; k++) {
                    tokens_[k] = address(tokens[k]);
                }
                if (!haveCommon(tokens_, vaults)) continue;
                IDefiCollector.UserData memory userData = data[j].users[0];

                Response memory response;
                response.balance = userData.lpAmount;
                response.vault = data[j].pool;
                response.isDefi = true;
                response.underlyingTokens = tokens_;
                response.underlyingAmounts = data[j].balances;
                response.underlyingTokenDecimals = new uint8[](tokens.length);
                for (uint256 k = 0; k < tokens.length; k++) {
                    response.underlyingTokenDecimals[k] = IERC20Metadata(
                        tokens_[k]
                    ).decimals();
                }
                response.totalSupply = data[j].totalSupply;
                response.pricesX96 = new uint256[](tokens.length);

                for (uint256 k = 0; k < tokens.length; k++) {
                    response.pricesX96[k] = convertTokenIntoEth(
                        responses,
                        tokens_[k],
                        Q96
                    );
                    response.totalValueETH += FullMath.mulDiv(
                        response.pricesX96[k],
                        response.underlyingAmounts[k],
                        Q96
                    );
                }

                response.totalValueUSDC = convertWethToUSDC(
                    response.totalValueETH
                );
                response.userBalanceETH = FullMath.mulDiv(
                    response.totalValueETH,
                    response.balance,
                    response.totalSupply
                );
                response.userBalanceUSDC = convertWethToUSDC(
                    response.userBalanceETH
                );
                response.lpPriceD18 = FullMath.mulDiv(
                    response.totalValueUSDC,
                    D18,
                    response.totalSupply
                );
                fullResponses[itr++] = response;
            }
        }

        assembly {
            mstore(fullResponses, itr)
        }
    }

    function getVaultResponse(
        Response[] memory responses,
        address vault
    ) public pure returns (Response memory r) {
        for (uint256 i = 0; i < responses.length; i++) {
            Response memory response = responses[i];
            if (response.vault == vault) return response;
        }
    }

    function convertTokenIntoEth(
        Response[] memory responses,
        address token,
        uint256 amount
    ) public view returns (uint256 ethAmount) {
        Response memory r = getVaultResponse(responses, token);
        if (r.vault != address(0))
            return FullMath.mulDiv(amount, r.totalValueETH, r.totalSupply);
        if (token == weth || token == steth) return amount;
        if (token == wsteth) return IWSteth(wsteth).getStETHByWstETH(amount);
        // by default == 1
        return amount;
    }

    function test() external pure {}
}
