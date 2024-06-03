// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IDefiCollector.sol";

import "../../../src/utils/DefaultAccessControl.sol";

interface ICurvePool is IERC20 {
    function N_COINS() external view returns (uint256);
    function coins(uint256 i) external view returns (address);
}

contract CurveCollector is IDefiCollector, DefaultAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private pools_;

    constructor(address admin_) DefaultAccessControl(admin_) {}

    function addPool(address pool) external {
        _requireAdmin();
        pools_.add(pool);
    }

    function removePool(address pool) external {
        _requireAdmin();
        pools_.remove(pool);
    }

    function collect(
        address[] memory users
    ) public view override returns (Data[] memory data) {
        address[] memory pools = pools_.values();
        data = new Data[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            uint256 n = ICurvePool(pools[i]).N_COINS();
            data[i].tokens = new IERC20[](n);
            data[i].balances = new uint256[](n);
            data[i].pool = pools[i];
            for (uint256 j = 0; j < n; j++) {
                data[i].tokens[j] = IERC20(ICurvePool(pools[i]).coins(j));
                data[i].balances[j] = data[i].tokens[j].balanceOf(pools[i]);
            }
            data[i].users = new UserData[](users.length);
            for (uint256 j = 0; j < users.length; j++) {
                data[i].users[j].user = users[j];
                data[i].users[j].lpAmount = ICurvePool(pools[i]).balanceOf(
                    users[j]
                );
            }
        }
    }

    function test() external pure {}
}
