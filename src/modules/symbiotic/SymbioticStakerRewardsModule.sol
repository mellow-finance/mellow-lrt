// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import {IStakerRewards} from "../../interfaces/external/symbiotic/rewards/stakerRewards/IStakerRewards.sol";
import "../DefaultModule.sol";

contract SymbioticStakerRewardsModule is DefaultModule {
    function claimRewards(
        address stakerRewards,
        address recipient,
        address token,
        bytes calldata data
    ) external onlyDelegateCall {
        IStakerRewards(stakerRewards).claimRewards(recipient, token, data);
    }

    function claimRewards(
        address defaultStakerRewards,
        address recipient,
        address token,
        address network,
        uint256 maxRewards,
        bytes[] calldata activeSharesOfHints
    ) external onlyDelegateCall {
        bytes memory data = abi.encode(
            network,
            maxRewards,
            activeSharesOfHints
        );
        IStakerRewards(defaultStakerRewards).claimRewards(
            recipient,
            token,
            data
        );
    }
}
