// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./Fixture.sol";

contract Unit is Fixture {
    using SafeERC20 for IERC20;

    function _initializeVault() private {
        vm.startPrank(Constants.PROTOCOL_GOVERNANCE_ADMIN);

        address[] memory tokens = new address[](1);
        tokens[0] = Constants.STETH;
        uint256[] memory weights = new uint256[](1);
        weights[0] = 1 ether;

        ratiosOracle.updateRatios(address(vault), tokens, weights);

        protocolGovernance.stageMaximalTotalSupply(
            address(vault),
            type(uint256).max
        );
        protocolGovernance.commitMaximalTotalSupply(address(vault));

        protocolGovernance.stageDelegateModuleApproval(
            address(bondDepositModule)
        );
        protocolGovernance.stageDelegateModuleApproval(
            address(bondWithdrawalModule)
        );
        protocolGovernance.commitDelegateModuleApproval(
            address(bondDepositModule)
        );
        protocolGovernance.commitDelegateModuleApproval(
            address(bondWithdrawalModule)
        );

        validator.grantRole(address(vault), Constants.DEFAULT_BOND_ROLE);
        validator.grantContractRole(
            address(bondDepositModule),
            Constants.DEFAULT_BOND_ROLE
        );
        validator.grantContractRole(
            address(bondWithdrawalModule),
            Constants.DEFAULT_BOND_ROLE
        );
        validator.setCustomValidator(
            address(bondDepositModule),
            address(customValidator)
        );
        validator.setCustomValidator(
            address(bondWithdrawalModule),
            address(customValidator)
        );
        customValidator.addSupported(address(stethDefaultBond));

        newPrank(Constants.VAULT_ADMIN);
        vault.addToken(Constants.STETH);
        vault.setTvlModule(address(erc20TvlModule), new bytes(0));
        address[] memory bonds = new address[](1);
        bonds[0] = address(stethDefaultBond);
        vault.setTvlModule(
            address(bondTvlModule),
            abi.encode(IDefaultBondTvlModule.Params({bonds: bonds}))
        );

        // initial deposit
        newPrank(address(this));
        mintSteth(address(this), 10 ether);
        mintSteth(Constants.DEPOSITOR, 10 ether);
    }

    function testAddToken() external {
        _initializeVault();
        newPrank(Constants.VAULT_ADMIN);
        for (uint256 i = 0; i < 4; i++) {
            vault.addToken(address(uint160(i + 1)));
        }
    }

    function testRemoveToken() external {
        _initializeVault();

        newPrank(Constants.VAULT_ADMIN);

        address[5] memory tokensToAdd = [
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            0xB8c77482e45F1F44dE1745F52C74426C631bDD52,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0x582d872A1B094FC48F5DE31D3B73F2D9bE47def1,
            0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE
        ];

        for (uint256 i = 0; i < 5; i++) {
            vault.addToken(tokensToAdd[i]);
        }

        vm.expectRevert(abi.encodeWithSignature("InvalidToken()"));
        vault.removeToken(address(1));

        for (uint256 i = 0; i < 5; i++) {
            vault.removeToken(tokensToAdd[i]);
        }
    }
}
