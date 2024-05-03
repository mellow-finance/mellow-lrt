// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "./Constants.sol";

import "./mocks/DefaultBondMock.sol";

contract Fixture is Test {
    using SafeERC20 for IERC20;

    uint256 public constant Q96 = 2 ** 96;
    uint256 public constant D9 = 1e9;

    VaultConfigurator public configurator;
    ManagedRatiosOracle public ratiosOracle;
    ChainlinkOracle public oracle;
    ManagedValidator public validator;
    DefaultBondValidator public customValidator;
    Vault public vault;

    DefaultBondModule public bondModule;
    DefaultBondTvlModule public bondTvlModule;

    ERC20SwapModule public erc20SwapModule;
    ERC20SwapValidator public erc20SwapValidator;

    ERC20TvlModule public erc20TvlModule;

    DefaultBondMock public wstethDefaultBond;

    function mintWsteth(address user, uint256 amount) public {
        deal(address(this), 2 * amount);
        ISteth(payable(Constants.STETH)).submit{value: 2 * amount}(address(0));
        IERC20(Constants.STETH).safeIncreaseAllowance(
            Constants.WSTETH,
            2 * amount
        );
        IWSteth(Constants.WSTETH).wrap(2 * amount);
        IERC20(Constants.WSTETH).safeTransfer(user, amount);
    }

    function newPrank(address newUser) public {
        vm.stopPrank();
        vm.startPrank(newUser);
    }

    function setUp() external {
        ratiosOracle = new ManagedRatiosOracle();
        oracle = new ChainlinkOracle();
        validator = new ManagedValidator(Constants.PROTOCOL_GOVERNANCE_ADMIN);
        customValidator = new DefaultBondValidator(
            Constants.PROTOCOL_GOVERNANCE_ADMIN
        );

        bondModule = new DefaultBondModule();
        bondTvlModule = new DefaultBondTvlModule();

        erc20SwapModule = new ERC20SwapModule();
        erc20SwapValidator = new ERC20SwapValidator(
            Constants.PROTOCOL_GOVERNANCE_ADMIN
        );

        wstethDefaultBond = new DefaultBondMock(Constants.WSTETH);

        erc20TvlModule = new ERC20TvlModule();

        vault = new Vault("name", "symbol", Constants.VAULT_ADMIN);

        configurator = VaultConfigurator(address(vault.configurator()));
    }
}
