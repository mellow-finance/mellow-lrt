// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/validators/IValidator.sol";
import "../utils/DefaultAccessControl.sol";

import "../modules/symbiotic/DefaultBondDepositModule.sol";
import "../modules/symbiotic/DefaultBondWithdrawalModule.sol";

contract SymbioticBondValidator is IValidator, DefaultAccessControl {
    constructor(address admin) DefaultAccessControl(admin) {}

    mapping(address => bool) public isSupportedBond;

    function setSupportedBond(address bond, bool flag) external {
        _requireAdmin();
        isSupportedBond[bond] = flag;
    }

    function validate(address, address, bytes calldata data) external view {
        if (data.length != 0x44)
            revert("SymbioticBondValidator: invalid length");
        bytes4 selector = bytes4(data[:4]);
        if (
            selector == DefaultBondDepositModule.deposit.selector ||
            selector == DefaultBondWithdrawalModule.withdraw.selector
        ) {
            (address bond, uint256 amount) = abi.decode(
                data[4:],
                (address, uint256)
            );
            if (!isSupportedBond[bond]) revert Forbidden();
            if (amount == 0) revert Forbidden();
        } else revert Forbidden();
    }
}
