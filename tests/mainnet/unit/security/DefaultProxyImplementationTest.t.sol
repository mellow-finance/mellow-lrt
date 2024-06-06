// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../../../../src/security/DefaultProxyImplementation.sol";
import "../../Constants.sol";

contract Unit is Test {
    function test() external {
        DefaultProxyImplementation impl = new DefaultProxyImplementation(
            "impl",
            "impl"
        );
        deal(address(impl), address(this), 1 ether);
        vm.expectRevert(abi.encodeWithSignature("Locked()"));
        impl.transfer(address(this), 1 ether);
    }
}
