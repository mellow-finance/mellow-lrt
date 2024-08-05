// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDepositSecurityModule {
    struct Signature {
        bytes32 r;
        bytes32 vs;
    }

    function depositBufferedEther(
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 depositRoot,
        uint256 stakingModuleId,
        uint256 nonce,
        bytes calldata depositCalldata,
        Signature[] calldata sortedGuardianSignatures
    ) external;

    function addGuardian(address addr, uint256 newQuorum) external;

    function getOwner() external view returns (address);

    function setMinDepositBlockDistance(uint256 newValue) external;

    function getGuardianIndex(address) external view returns (int256);

    function STAKING_ROUTER() external view returns (address);

    function DEPOSIT_CONTRACT() external view returns (address);

    function getMaxDeposits() external view returns (uint256);
}
