// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./IDeploy.sol";

contract AcceptanceTest {
    function validateParameters(
        IDeploy.DeployParameters memory deployParams,
        IDeploy.DeploySetup memory setup
    ) external view {}
}
