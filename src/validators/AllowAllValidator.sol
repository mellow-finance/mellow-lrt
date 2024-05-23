// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.25;

import "../interfaces/validators/IAllowAllValidator.sol";

contract AllowAllValidator is IAllowAllValidator {
    /// @inheritdoc IValidator
    function validate(address, address, bytes calldata) external pure {}
}
