// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IDefiCollector {
    struct UserData {
        address user;
        uint256 lpAmount;
    }

    struct Data {
        UserData[] users;
        IERC20[] tokens;
        uint256[] balances;
        uint256 totalSupply;
        address pool;
    }

    function collect(
        address[] memory users
    ) external view returns (Data[] memory data);
}
