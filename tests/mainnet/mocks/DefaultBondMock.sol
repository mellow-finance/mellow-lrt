// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../../src/interfaces/external/symbiotic/IDefaultBond.sol";

contract DefaultBondMock is IDefaultBond, ERC20 {
    address public immutable asset;

    function testMock() public {}

    constructor(address asset_) ERC20("mock", "mock") {
        asset = asset_;
    }

    function deposit(
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        uint256 lpAmount = IERC20(asset).balanceOf(address(this)) -
            balanceBefore;
        _mint(recipient, lpAmount);
        return lpAmount;
    }

    function deposit(
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external pure returns (uint256) {}

    function withdraw(address recipient, uint256 amount) external {
        _burn(msg.sender, amount);
        IERC20(asset).transfer(recipient, amount);
    }

    function limit() external view returns (uint256) {
        return type(uint256).max;
    }

    function totalRepaidDebt() external pure returns (uint256) {}

    function issuerRepaidDebt(address) external pure returns (uint256) {}

    function recipientRepaidDebt(address) external pure returns (uint256) {}

    function repaidDebt(address, address) external pure returns (uint256) {}

    function totalDebt() external pure returns (uint256) {}

    function issuerDebt(address) external pure returns (uint256) {}

    function recipientDebt(address) external pure returns (uint256) {}

    function debt(address, address) external pure returns (uint256) {}

    function issueDebt(address, uint256) external pure {}
}
