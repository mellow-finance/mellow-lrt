// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDefiCollector.sol";

import "../../../src/utils/DefaultAccessControl.sol";

interface IBalancerVault {
    function getPoolTokens(
        bytes32 poolId
    )
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getPool(bytes32 poolId) external view returns (address, bytes32);
}

contract BalancerCollector is IDefiCollector, DefaultAccessControl {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    IBalancerVault public immutable balancerVault;

    EnumerableSet.Bytes32Set private pools_;

    constructor(address admin_, address vault_) DefaultAccessControl(admin_) {
        balancerVault = IBalancerVault(vault_);
    }

    function addPool(bytes32 poolId) external {
        _requireAdmin();
        pools_.add(poolId);
    }

    function removePool(bytes32 poolId) external {
        _requireAdmin();
        pools_.remove(poolId);
    }

    function collect(
        address[] memory users
    ) public view override returns (Data[] memory data) {
        bytes32[] memory poolIds = pools_.values();
        data = new Data[](poolIds.length);
        for (uint256 i = 0; i < poolIds.length; i++) {
            (data[i].tokens, data[i].balances, ) = balancerVault.getPoolTokens(
                poolIds[i]
            );
            (address pool, ) = balancerVault.getPool(poolIds[i]);
            data[i].pool = pool;
            data[i].users = new UserData[](users.length);
            for (uint256 j = 0; j < users.length; j++) {
                data[i].users[j].user = users[j];
                data[i].users[j].lpAmount = IERC20(pool).balanceOf(users[j]);
            }
        }
    }

    function test() external pure {}
}
