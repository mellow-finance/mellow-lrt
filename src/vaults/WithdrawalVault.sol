// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WithdrawalVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct WithdrawalRequest {
        address[] tokens;
        uint256[] amounts;
    }

    mapping(address => WithdrawalRequest[]) private _requests;

    address public immutable vault;

    modifier onlyVault() {
        require(
            msg.sender == vault,
            "WithdrawalVault: caller is not the vault"
        );
        _;
    }

    constructor() {
        vault = msg.sender;
    }

    function push(
        address to,
        address[] memory tokens,
        uint256[] memory amounts
    ) external onlyVault nonReentrant {
        _requests[to].push(WithdrawalRequest(tokens, amounts));
    }

    function claim(
        uint256 n
    ) external nonReentrant returns (uint256 numberOfRequests) {
        address user = msg.sender;
        WithdrawalRequest[] storage userRequests = _requests[user];
        for (uint256 i = 0; i < n && userRequests.length != 0; i++) {
            WithdrawalRequest memory request = userRequests[i];
            for (uint256 j = 0; j < request.tokens.length; j++) {
                if (request.amounts[j] == 0) continue;
                IERC20(request.tokens[j]).safeTransfer(
                    user,
                    request.amounts[j]
                );
            }
            numberOfRequests++;
            userRequests.pop();
        }
    }

    function requests(
        address user
    ) external view returns (WithdrawalRequest[] memory) {
        return _requests[user];
    }
}
