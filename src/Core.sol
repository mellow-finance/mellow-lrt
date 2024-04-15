// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICore.sol";
import "./interfaces/IMellowLRT.sol";

import "./libraries/external/FullMath.sol";

contract Core is ICore {
    using SafeERC20 for IERC20;

    IOracle public oracle;
    ILrtService public lrtService;
    uint256 public lrtId;

    address public owner;
    IMellowLRT public mellowLRT;
    address public baseToken;

    constructor(address owner_, IMellowLRT mellowLRT_, address baseToken_) {
        owner = owner_;
        mellowLRT = mellowLRT_;
        baseToken = baseToken_;
    }

    function deposit(
        address to,
        address token,
        uint256 amount,
        uint256 minLpAmount
    ) external returns (uint256 lpAmount) {
        address user = msg.sender;
        lpAmount = FullMath.mulDiv(
            mellowLRT.totalSupply(),
            oracle.getValue(token, amount, baseToken),
            tvl()
        );

        if (lpAmount < minLpAmount) revert("Core: insufficient lpAmount");

        IERC20(token).transferFrom(user, address(this), amount);
        IERC20(token).forceApprove(address(lrtService), amount);

        lrtService.deposit(lrtId, token, amount);

        mellowLRT.mint(to, lpAmount);
    }

    function withdraw(
        address to,
        address token,
        uint256 lpAmount,
        uint256 minAmount
    ) external returns (uint256 amount) {
        address user = msg.sender;
        uint256 balance = IERC20(mellowLRT).balanceOf(user);
        if (balance < lpAmount) {
            lpAmount = balance;
        }

        uint256 value = FullMath.mulDiv(
            tvl(),
            lpAmount,
            mellowLRT.totalSupply()
        );
        amount = oracle.getValue(baseToken, value, token);

        if (amount < minAmount) revert("Core: insufficient token amount");

        lrtService.withdraw(lrtId, token, amount);
        IERC20(token).safeTransfer(to, amount);

        mellowLRT.burn(user, lpAmount);
    }

    function compound(bytes memory params) external {
        require(msg.sender == owner, "Core: not owner");
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
