// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";
import "../../../src/interfaces/external/lido/IWSteth.sol";
import "../../../src/interfaces/IVault.sol";
import "../../../src/interfaces/oracles/IChainlinkOracle.sol";

import "../../../src/libraries/external/FullMath.sol";

contract Collector {
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
        uint256 maximalTotalSupply; // limit of total supply of the vault
        uint256 userBalanceETH; // user vault balance in ETH
        uint256 userBalanceUSDC; // user vault balance in USDC
        uint256 totalValueETH; // total value of the vault in ETH
        uint256 totalValueUSDC; // total value of the vault in USDC
        uint256 totalValueWSTETH; // total value of the vault in WSTETH
        uint256 totalValueBaseToken; // total value of the vault in base token
        uint256 maximalTotalSupplyETH; // eth value for max limit total supply
        uint256 maximalTotalSupplyUSDC; // usdc value for max limit total supply
        uint256 maximalTotalSupplyWSTETH; // wsteth value for max limit total supply
        uint256 maximalTotalSupplyBaseToken; // base token value for max limit total supply
        uint256 lpPriceD18; // LP price in USDC weis 1e8 (due to chainlink decimals)
        uint256 lpPriceETHD18; // LP price in ETH weis 1e8 (due to chainlink decimals)
        uint256 lpPriceWSTETHD18; // LP price in WSTETH weis 1e8 (due to chainlink decimals)
        uint256 lpPriceBaseTokenD18; // LP price in Base token weis 1e8 (due to chainlink decimals)
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
    address public immutable ena;
    address public immutable susde;
    address public immutable wbtc;

    IAggregatorV3 public immutable wstethOracle;
    IAggregatorV3 public immutable wethOracle;
    IAggregatorV3 public immutable wbtcOracle;

    constructor(
        address wsteth_,
        address weth_,
        address steth_,
        address ena_,
        address susde_,
        address wbtc_,
        IAggregatorV3 _wstethOracle,
        IAggregatorV3 _wethToUSDOracle,
        IAggregatorV3 _wbtcToUSDOracle
    ) {
        wsteth = wsteth_;
        weth = weth_;
        steth = steth_;
        ena = ena_;
        susde = susde_;
        wbtc = wbtc_;
        wstethOracle = _wstethOracle;
        wethOracle = _wethToUSDOracle;
        wbtcOracle = _wbtcToUSDOracle;
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
                    uint256 underlyingPriceX96 = oracle.priceX96(
                        address(vault),
                        responses[i].underlyingTokens[j]
                    );
                    responses[i].pricesX96[
                        j
                    ] = convertBaseTokenPriceToWethPrice(
                        underlyingPriceX96,
                        IChainlinkOracle(address(oracle)).baseTokens(
                            address(vault)
                        )
                    );
                    responses[i].underlyingTokenDecimals[j] = IERC20Metadata(
                        responses[i].underlyingTokens[j]
                    ).decimals();
                    responses[i].totalValueETH += FullMath.mulDiv(
                        responses[i].pricesX96[j],
                        responses[i].underlyingAmounts[j],
                        Q96
                    );
                    responses[i].totalValueBaseToken += FullMath.mulDiv(
                        underlyingPriceX96,
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
                responses[i].maximalTotalSupply = vault
                    .configurator()
                    .maximalTotalSupply();
                responses[i].maximalTotalSupplyETH = FullMath.mulDiv(
                    responses[i].maximalTotalSupply,
                    responses[i].totalValueETH,
                    responses[i].totalSupply
                );
                responses[i].maximalTotalSupplyWSTETH = IWSteth(wsteth)
                    .getWstETHByStETH(responses[i].maximalTotalSupplyETH);
                responses[i].totalValueWSTETH = IWSteth(wsteth)
                    .getWstETHByStETH(responses[i].totalValueETH);
                responses[i].maximalTotalSupplyUSDC = convertWethToUSDC(
                    responses[i].maximalTotalSupplyETH
                );
                responses[i].lpPriceETHD18 = FullMath.mulDiv(
                    responses[i].totalValueETH,
                    D18,
                    responses[i].totalSupply
                );
                responses[i].lpPriceWSTETHD18 = FullMath.mulDiv(
                    responses[i].totalValueWSTETH,
                    D18,
                    responses[i].totalSupply
                );

                responses[i].maximalTotalSupplyBaseToken = FullMath.mulDiv(
                    responses[i].maximalTotalSupply,
                    responses[i].totalValueBaseToken,
                    responses[i].totalSupply
                );

                responses[i].lpPriceWSTETHD18 = FullMath.mulDiv(
                    responses[i].totalValueBaseToken,
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

        return responses;
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
            response.totalValueBaseToken,
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
        address /* user */,
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
        isDepositorWhitelisted = true;
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
        address /* user */
    ) external view returns (FetchDepositAmountsResponse memory r) {
        if (IVault(vault).configurator().isDepositLocked()) return r;
        r.isDepositPossible = true;
        r.isDepositorWhitelisted = true;
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

    function convertBaseTokenPriceToWethPrice(
        uint256 priceX96,
        address token
    ) public view returns (uint256 wethPriceX96) {
        if (token == weth) return priceX96;

        if (token == ena) {
            IUniswapV3Pool pool = IUniswapV3Pool(
                0xc3Db44ADC1fCdFd5671f555236eae49f4A8EEa18
            );
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint256 enaToWethPriceX96 = FullMath.mulDiv(
                sqrtPriceX96,
                sqrtPriceX96,
                Q96
            );
            return FullMath.mulDiv(priceX96, enaToWethPriceX96, Q96);
        } else if (token == susde) {
            IUniswapV3Pool pool = IUniswapV3Pool(
                0x7C45F7ff7dDeaC1af333E469f4B99bbd75Ee5495
            );
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint256 wstethToSusdePriceX96 = FullMath.mulDiv(
                sqrtPriceX96,
                sqrtPriceX96,
                Q96
            );

            return
                convertBaseTokenPriceToWethPrice(
                    FullMath.mulDiv(priceX96, Q96, wstethToSusdePriceX96),
                    wsteth
                );
        } else if (token == wsteth) {
            return IWSteth(wsteth).getStETHByWstETH(priceX96);
        } else if (token == wbtc) {
            (, int256 answer, , , ) = IAggregatorV3(
                0xdeb288F737066589598e9214E782fa5A8eD689e8
            ).latestRoundData();
            return FullMath.mulDiv(priceX96, uint256(answer), 1e8);
        } else {
            revert("Unsupported token");
        }
    }
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}
