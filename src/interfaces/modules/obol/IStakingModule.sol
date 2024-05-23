// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../external/lido/IWeth.sol";
import "../../external/lido/ISteth.sol";
import "../../external/lido/IWSteth.sol";
import "../../external/lido/IWithdrawalQueue.sol";
import "../../external/lido/IDepositSecurityModule.sol";

interface IStakingModule {
    error NotEnoughWeth();
    error InvalidWithdrawalQueueState();

    function weth() external view returns (address);

    function steth() external view returns (address);

    function wsteth() external view returns (address);

    function depositSecurityModule()
        external
        view
        returns (IDepositSecurityModule);

    function withdrawalQueue() external view returns (IWithdrawalQueue);

    function stakingModuleId() external view returns (uint256);

    function convert(uint256 amount) external;

    function convertAndDeposit(
        uint256 amount,
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 nonce,
        bytes calldata depositCalldata,
        IDepositSecurityModule.Signature[] calldata sortedGuardianSignatures
    ) external;
}
