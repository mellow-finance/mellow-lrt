// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "./DeployInterfaces.sol";

contract BytecodeValidator {
    function validateBytecode(
        DeployInterfaces.DeployParameters memory deployParams,
        DeployInterfaces.DeploySetup memory setup
    ) public view {
        // TBD
    }
}
