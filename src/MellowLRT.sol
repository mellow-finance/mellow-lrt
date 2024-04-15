// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IMellowLRT.sol";

import "./libraries/external/FullMath.sol";

contract MellowLRT is IMellowLRT, ERC20 {
    using SafeERC20 for IERC20;

    IOracle public immutable oracle;
    ILrtService public immutable lrtService;
    uint256 public immutable lrtId;
    address public immutable baseToken;

    constructor(
        string memory name,
        string memory symbol,
        IOracle oracle_,
        address baseToken_,
        ILrtService lrtService_,
        uint256 lrtId_
    ) ERC20(name, symbol) {
        baseToken = baseToken_;
        oracle = oracle_;
        lrtService = lrtService_;
        lrtId = lrtId_;
    }

    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 minLpAmount
    ) external returns (uint256 lpAmount) {
        address user = msg.sender;
        lpAmount = FullMath.mulDiv(
            totalSupply(),
            oracle.getValue(token, amount, baseToken),
            tvl()
        );

        if (lpAmount < minLpAmount) revert("Core: insufficient lpAmount");

        IERC20(token).transferFrom(user, address(this), amount);
        IERC20(token).forceApprove(address(lrtService), amount);

        lrtService.deposit(lrtId, token, amount);

        _mint(to, lpAmount);
    }

    function withdraw(
        address to,
        address token,
        uint256 lpAmount,
        uint256 minAmount
    ) external returns (uint256 amount) {
        address user = msg.sender;
        uint256 balance = balanceOf(user);
        if (balance < lpAmount) {
            lpAmount = balance;
        }

        uint256 value = FullMath.mulDiv(tvl(), lpAmount, totalSupply());
        amount = oracle.getValue(baseToken, value, token);

        if (amount < minAmount) revert("Core: insufficient token amount");

        lrtService.withdraw(lrtId, token, amount);
        IERC20(token).safeTransfer(to, amount);

        _burn(user, lpAmount);
    }

    function compound(bytes memory params) external {
        lrtService.compound(params);
    }

    function tvl() public view returns (uint256 value) {
        (address[] memory tokens, uint256[] memory amounts) = lrtService
            .getTokensAndAmounts(lrtId);
        for (uint256 i = 0; i < tokens.length; i++) {
            value += oracle.getValue(tokens[i], amounts[i], baseToken);
        }
    }
}
