// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";

import "./mocks/DefaultBondMock.sol";

contract Fixture is Test {
    using SafeERC20 for IERC20;

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 1e9;

    ProtocolGovernance public protocolGovernance;
    ManagedRatiosOracle public ratiosOracle;
    ChainlinkOracle public oracle;
    ManagedValidator public validator;
    SymbioticBondValidator public customValidator;
    Vault public vault;

    DefaultBondDepositModule public bondDepositModule;
    DefaultBondWithdrawalModule public bondWithdrawalModule;
    DefaultBondTvlModule public bondTvlModule;

    ERC20TvlModule public erc20TvlModule;

    DefaultBondMock public stethDefaultBond;

    function mintSteth(address user, uint256 amount) public {
        deal(address(this), amount + 1);
        ISteth(payable(Constants.STETH)).submit{value: amount + 1}(address(0));
        IERC20(Constants.STETH).safeTransfer(user, amount);
    }

    function newPrank(address newUser) public {
        vm.stopPrank();
        vm.startPrank(newUser);
    }

    function setUp() external {
        protocolGovernance = new ProtocolGovernance(
            Constants.PROTOCOL_GOVERNANCE_ADMIN
        );
        ratiosOracle = new ManagedRatiosOracle(
            Constants.PROTOCOL_GOVERNANCE_ADMIN
        );
        oracle = new ChainlinkOracle(
            Constants.PROTOCOL_GOVERNANCE_ADMIN,
            Constants.STETH
        );
        validator = new ManagedValidator(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        customValidator = new SymbioticBondValidator(
            Constants.PROTOCOL_GOVERNANCE_ADMIN
        );

        bondDepositModule = new DefaultBondDepositModule();
        bondWithdrawalModule = new DefaultBondWithdrawalModule();
        bondTvlModule = new DefaultBondTvlModule();

        stethDefaultBond = new DefaultBondMock(Constants.STETH);

        erc20TvlModule = new ERC20TvlModule();

        vault = new Vault(
            "name",
            "symbol",
            Constants.VAULT_ADMIN,
            address(protocolGovernance),
            address(ratiosOracle),
            address(oracle),
            address(validator)
        );
    }
}
