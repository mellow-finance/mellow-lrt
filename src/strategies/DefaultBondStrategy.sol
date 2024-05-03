// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/strategies/IDefaultBondStrategy.sol";

import "../libraries/external/FullMath.sol";

import "../utils/DefaultAccessControl.sol";

contract DefaultBondStrategy is IDefaultBondStrategy, DefaultAccessControl {
    /// @inheritdoc IDefaultBondStrategy
    uint256 public constant Q96 = 2 ** 96;

    /// @inheritdoc IDefaultBondStrategy
    IVault public immutable vault;
    /// @inheritdoc IDefaultBondStrategy
    IERC20TvlModule public immutable erc20TvlModule;
    /// @inheritdoc IDefaultBondStrategy
    IDefaultBondModule public immutable bondModule;

    /// @inheritdoc IDefaultBondStrategy
    mapping(address => bytes) public tokenToData;

    constructor(
        address admin,
        IVault vault_,
        IERC20TvlModule erc20TvlModule_,
        IDefaultBondModule bondModule_
    ) DefaultAccessControl(admin) {
        vault = vault_;
        erc20TvlModule = erc20TvlModule_;
        bondModule = bondModule_;
    }

    /// @inheritdoc IDefaultBondStrategy
    function setData(address token, Data[] memory data) external {
        _requireAdmin();
        if (token == address(0)) revert AddressZero();
        uint256 cumulativeRatio = 0;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i].bond == address(0)) revert AddressZero();
            cumulativeRatio += data[i].ratioX96;
        }
        if (cumulativeRatio != Q96) revert InvalidCumulativeRatio();
        tokenToData[token] = abi.encode(data);
    }

    function _deposit() private {
        ITvlModule.Data[] memory tvl = erc20TvlModule.tvl(address(vault));
        for (uint256 i = 0; i < tvl.length; i++) {
            if (tvl[i].token != tvl[i].underlyingToken) continue;
            address token = tvl[i].token;
            bytes memory data_ = tokenToData[token];
            if (data_.length == 0) continue;
            Data[] memory data = abi.decode(data_, (Data[]));
            if (data.length == 0) continue;
            for (uint256 j = 0; j < data.length; j++) {
                uint256 amount = FullMath.mulDiv(
                    tvl[i].amount,
                    data[j].ratioX96,
                    Q96
                );
                if (amount == 0) continue;
                vault.delegateCall(
                    address(bondModule),
                    abi.encodeWithSelector(
                        IDefaultBondModule.deposit.selector,
                        data[j].bond,
                        amount
                    )
                );
            }
        }
    }

    /// @inheritdoc IDepositCallback
    function depositCallback(uint256[] memory, uint256) external override {
        if (msg.sender != address(vault)) _requireAtLeastOperator();
        _deposit();
    }

    /// @inheritdoc IDefaultBondStrategy
    function processAll() external {
        _requireAtLeastOperator();
        _processWithdrawals(vault.pendingWithdrawers());
    }

    /// @inheritdoc IDefaultBondStrategy
    function processWithdrawals(address[] memory users) external {
        if (users.length == 0) return;
        if (users.length > 1 || users[0] != msg.sender)
            _requireAtLeastOperator();
        _processWithdrawals(users);
    }

    function _processWithdrawals(address[] memory users) private {
        if (users.length == 0) return;

        address[] memory tokens = vault.underlyingTokens();
        for (uint256 index = 0; index < tokens.length; index++) {
            bytes memory data_ = tokenToData[tokens[index]];
            if (data_.length == 0) continue;
            Data[] memory data = abi.decode(data_, (Data[]));
            for (uint256 i = 0; i < data.length; i++) {
                vault.delegateCall(
                    address(bondModule),
                    abi.encodeWithSelector(
                        IDefaultBondModule.withdraw.selector,
                        data[i].bond,
                        IERC20(data[i].bond).balanceOf(address(vault))
                    )
                );
            }
        }

        vault.processWithdrawals(users);
        _deposit();
    }
}
