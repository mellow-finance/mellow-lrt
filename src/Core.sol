// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IMellowLRT.sol";

import "./libraries/external/FullMath.sol";

import "./MellowLRT.sol";

contract Core {
    address public immutable owner;
    ILrtService public immutable lrtService;
    IOracle public immutable oracle;

    constructor(address owner_, ILrtService lrtService_, IOracle oracle_) {
        owner = owner_;
        lrtService = lrtService_;
        oracle = oracle_;
    }

    function createLRT(
        string memory name,
        string memory symbol,
        address baseToken,
        bytes memory params
    ) external returns (MellowLRT lrt) {
        require(msg.sender == owner, "Core: not owner");
        uint256 id = lrtService.createLRT(params);

        lrt = new MellowLRT(owner, baseToken, name, symbol, oracle, lrtService);
    }
}
