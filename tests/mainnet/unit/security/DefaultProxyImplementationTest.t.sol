// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../Constants.sol";
import "../../e2e/DeployLibrary.sol";

contract DefaultProxyImplementationUnitTest is
    Test,
    DefaultProxyImplementation
{
    address public immutable deployer = vm.createWallet("deployer").addr;
    string lpTokenNameDefault = "tokenName";
    string lpTokenSymbolDefault = "symbol";

    constructor()
        DefaultProxyImplementation(lpTokenNameDefault, lpTokenSymbolDefault)
    {}

    function testConstructorSuccess() external {
        DefaultProxyImplementation proxy = new DefaultProxyImplementation(
            lpTokenNameDefault,
            lpTokenSymbolDefault
        );
        assertNotEq(address(proxy), address(0));
    }

    function testUpdateLockedRevert() external {
        vm.expectRevert();
        _update(deployer, address(0), 0);
    }
}
