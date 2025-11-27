// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";

/**
 * @title ERC20 External Increase/Decrease Allowance Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with increaseAllowance and decreaseAllowance functions tested via external interface
 * @dev Testing Mode: EXTERNAL (test harness interacts with token through external interface)
 * @dev This contract contains 2 properties that test increaseAllowance() and decreaseAllowance()
 * @dev functions via external interface. These functions provide safer alternatives to approve()
 * @dev by modifying existing allowances rather than setting absolute values.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC20ExternalIncreaseAllowanceProperties {
 * @dev     constructor() {
 * @dev         // Deploy or reference your ERC20 token with increase/decrease allowance
 * @dev         token = ITokenMock(address(new MyToken()));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20ExternalIncreaseAllowanceProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}


    /* ================================================================

                    ALLOWANCE MODIFICATION PROPERTIES

       Description: Properties verifying increaseAllowance/decreaseAllowance
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title IncreaseAllowance Updates Allowance Correctly
    /// @notice Increasing allowance should add to the existing allowance value
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `increaseAllowance(spender, amount)`, the allowance becomes
    /// @dev `previousAllowance + amount`
    /// @dev The increaseAllowance() function provides a safer alternative to approve() by
    /// @dev incrementing the existing allowance rather than setting an absolute value. This
    /// @dev prevents certain race conditions where a spender could potentially spend both the
    /// @dev old and new allowance if approve() is called twice in quick succession. This property
    /// @dev verifies the arithmetic correctness of the increase operation.
    /// @custom:property-id ERC20-EXTERNAL-ALLOWANCE-MODIFY-051
    function test_ERC20external_setAndIncreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 increaseAmount
    ) public {
        bool r = token.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = token.increaseAllowance(target, increaseAmount);
        assertWithMsg(r == true, "Failed to increase allowance");
        assertEq(
            token.allowance(address(this), target),
            initialAmount + increaseAmount,
            "Allowance not increased correctly"
        );
    }

    /// @title DecreaseAllowance Updates Allowance Correctly
    /// @notice Decreasing allowance should subtract from the existing allowance value
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `decreaseAllowance(spender, amount)`, the allowance becomes
    /// @dev `previousAllowance - amount`
    /// @dev The decreaseAllowance() function provides a safer way to reduce allowances by
    /// @dev decrementing the existing value rather than setting a new absolute value. This
    /// @dev avoids race conditions and provides clearer intent when reducing permissions. This
    /// @dev property verifies the arithmetic correctness of the decrease operation.
    /// @custom:property-id ERC20-EXTERNAL-ALLOWANCE-MODIFY-052
    function test_ERC20external_setAndDecreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 decreaseAmount
    ) public {
        bool r = token.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = token.decreaseAllowance(target, decreaseAmount);
        assertWithMsg(r == true, "Failed to decrease allowance");
        assertEq(
            token.allowance(address(this), target),
            initialAmount - decreaseAmount,
            "Allowance not decreased correctly"
        );
    }
}
