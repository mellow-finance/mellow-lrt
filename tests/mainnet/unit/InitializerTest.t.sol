// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../Constants.sol";
import "../e2e/DeployLibrary.sol";

contract InitializerTestUnit is Test {
    address public immutable deployer = vm.createWallet("deployer").addr;

    function testCheckTooLongNameRevert() external {
        string memory lpTokenName = "012345678901234567890123456789012345";
        string memory lpTokenSymbol = "symbol";

        Initializer initializer = new Initializer();

        vm.expectRevert("Too long name");
        initializer.initialize(lpTokenName, lpTokenSymbol, deployer);
    }

    function testCheckTooLongSymbolRevert() external {
        string memory lpTokenName = "name";
        string memory lpTokenSymbol = "012345678901234567890123456789012345";

        Initializer initializer = new Initializer();

        vm.expectRevert("Too long symbol");
        initializer.initialize(lpTokenName, lpTokenSymbol, deployer);
    }
}
