// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployLibrary.sol";

contract AcceptanceTest {
    function validateParameters(
        DeployLibrary.DeployParameters memory deployParams,
        DeployLibrary.DeploySetup memory setup
    ) external view {}
}
