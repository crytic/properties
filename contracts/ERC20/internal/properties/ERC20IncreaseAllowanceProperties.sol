// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title ERC20 Increase/Decrease Allowance Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with increaseAllowance and decreaseAllowance functions
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 2 properties that test increaseAllowance() and decreaseAllowance()
 * @dev functions, which provide safer alternatives to approve() by modifying existing allowances
 * @dev rather than setting absolute values.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyToken, CryticERC20IncreaseAllowanceProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         _mint(USER2, INITIAL_BALANCE);
 * @dev         _mint(USER3, INITIAL_BALANCE);
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20IncreaseAllowanceProperties is CryticERC20Base {
    constructor() {}


    /* ================================================================

                    ALLOWANCE MODIFICATION PROPERTIES

       Description: Properties verifying increaseAllowance/decreaseAllowance
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title IncreaseAllowance Updates Allowance Correctly
    /// @notice Increasing allowance should add to the existing allowance value
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `increaseAllowance(spender, amount)`, the allowance becomes
    /// @dev `previousAllowance + amount`
    /// @dev The increaseAllowance() function provides a safer alternative to approve() by
    /// @dev incrementing the existing allowance rather than setting an absolute value. This
    /// @dev prevents certain race conditions where a spender could potentially spend both the
    /// @dev old and new allowance if approve() is called twice in quick succession.
    /// @custom:property-id ERC20-ALLOWANCE-MODIFY-001
    function test_ERC20_setAndIncreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 increaseAmount
    ) public {
        bool r = this.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = this.increaseAllowance(target, increaseAmount);
        assertWithMsg(r == true, "Failed to increase allowance");
        assertEq(
            allowance(address(this), target),
            initialAmount + increaseAmount,
            "Allowance not increased correctly"
        );
    }

    /// @title DecreaseAllowance Updates Allowance Correctly
    /// @notice Decreasing allowance should subtract from the existing allowance value
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `decreaseAllowance(spender, amount)`, the allowance becomes
    /// @dev `previousAllowance - amount`
    /// @dev The decreaseAllowance() function provides a safer way to reduce allowances by
    /// @dev decrementing the existing value rather than setting a new absolute value. This
    /// @dev avoids race conditions and provides clearer intent when reducing permissions.
    /// @custom:property-id ERC20-ALLOWANCE-MODIFY-002
    function test_ERC20_setAndDecreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 decreaseAmount
    ) public {
        bool r = this.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = this.decreaseAllowance(target, decreaseAmount);
        assertWithMsg(r == true, "Failed to decrease allowance");
        assertEq(
            allowance(address(this), target),
            initialAmount - decreaseAmount,
            "Allowance not decreased correctly"
        );
    }
}
