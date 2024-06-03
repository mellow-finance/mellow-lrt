// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Collector {

    struct Data {
        uint256 poolLpPriceInLRT;
        uint256 poolLpPriceInUSDC;
        
    }

    function collect() external view returns (Data memory data) {


    }


    function test() external pure {}
}
