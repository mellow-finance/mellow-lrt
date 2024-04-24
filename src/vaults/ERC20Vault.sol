// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/vaults/IERC20Vault.sol";

import "./Subvault.sol";

contract ERC20Vault is IERC20Vault, Subvault {
    using SafeERC20 for IERC20;

    constructor(IRootVault rootVault_) Subvault(rootVault_) {}

    function addToken(address token) external onlyRootVault {}

    function removeToken(address token) external onlyRootVault {}

    function push(
        uint256[] memory tokenAmounts
    )
        external
        view
        atLeastOperator
        returns (uint256[] memory actualTokenAmounts)
    {
        actualTokenAmounts = tokenAmounts;
    }

    function pull(
        address to,
        uint256[] memory amounts
    )
        external
        atLeastOperatorOrRootVault
        returns (uint256[] memory actualTokenAmounts)
    {
        if (to == address(rootVault) || !rootVault.hasSubvault(to))
            revert InvalidAddress();
        address[] memory tokens_ = rootVault.tokens();
        if (tokens_.length != amounts.length) revert InvalidLength();
        actualTokenAmounts = amounts;
        for (uint256 i = 0; i < tokens_.length; i++) {
            uint256 balance = IERC20(tokens_[i]).balanceOf(address(this));
            if (balance < amounts[i]) {
                actualTokenAmounts[i] = balance;
            }
            IERC20(tokens_[i]).safeTransfer(to, actualTokenAmounts[i]);
        }
    }

    function tvl() external view returns (uint256[] memory amounts) {
        address[] memory tokens_ = rootVault.tokens();
        amounts = new uint256[](tokens_.length);
        for (uint256 i = 0; i < tokens_.length; i++) {
            amounts[i] = IERC20(tokens_[i]).balanceOf(address(this));
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, Subvault) returns (bool) {
        return
            interfaceId == type(IERC20Vault).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
