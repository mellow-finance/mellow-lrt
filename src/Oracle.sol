// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IOracle.sol";

contract Oracle is IOracle {
    function getValue(
        address token,
        uint256 amount,
        address target
    ) external view returns (uint256) {
        // get values from chainlink

        return 0;
    }
}
