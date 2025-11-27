// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";
import "../../../util/IHevm.sol";

/**
 * @title ERC20 External Pausable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with pause functionality tested via external interface
 * @dev Testing Mode: EXTERNAL (test harness interacts with token through external interface)
 * @dev This contract contains 2 properties that test pause/unpause mechanics via external
 * @dev interface, ensuring transfers are blocked when the contract is paused. Uses hevm cheatcodes
 * @dev to prank as the token owner for pause/unpause operations.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC20ExternalPausableProperties {
 * @dev     constructor() {
 * @dev         // Deploy or reference your pausable ERC20 token
 * @dev         token = ITokenMock(address(new MyPausableToken()));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20ExternalPausableProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}


    /* ================================================================

                        PAUSE PROPERTIES

       Description: Properties verifying pause/unpause mechanics
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Transfer Must Fail When Paused
    /// @notice Direct transfers should be blocked when contract is paused
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: When paused, `transfer(recipient, amount)` must return false or revert,
    /// @dev and balances must remain unchanged
    /// @dev The pause mechanism is a critical safety feature allowing contract administrators
    /// @dev to halt all token transfers in emergency situations. This property ensures the pause
    /// @dev works correctly by preventing any balance changes while paused. After testing, the
    /// @dev contract is unpaused to restore normal operations.
    /// @custom:property-id ERC20-EXTERNAL-PAUSE-051
    function test_ERC20external_pausedTransfer(
        address target,
        uint256 amount
    ) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 0);
        uint256 transfer_amount = amount % (balance_sender + 1);

        hevm.prank(token.owner());
        token.pause();

        bool r = token.transfer(target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(
            token.balanceOf(address(this)),
            balance_sender,
            "Transfer while paused altered source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Transfer while paused altered target balance"
        );

        hevm.prank(token.owner());
        token.unpause();
    }

    /// @title TransferFrom Must Fail When Paused
    /// @notice Delegated transfers should be blocked when contract is paused
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: When paused, `transferFrom(owner, recipient, amount)` must return false
    /// @dev or revert, and balances must remain unchanged
    /// @dev Like direct transfers, delegated transfers via transferFrom must also be blocked
    /// @dev during pause. This ensures complete halt of all token movements regardless of
    /// @dev transfer method, maintaining pause integrity across all transfer mechanisms. After
    /// @dev testing, the contract is unpaused to restore normal operations.
    /// @custom:property-id ERC20-EXTERNAL-PAUSE-052
    function test_ERC20external_pausedTransferFrom(
        address target,
        uint256 amount
    ) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 transfer_amount = amount % (balance_sender + 1);

        hevm.prank(token.owner());
        token.pause();

        bool r = token.transferFrom(msg.sender, target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender,
            "Transfer while paused altered source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Transfer while paused altered target balance"
        );

        hevm.prank(token.owner());
        token.unpause();
    }
}
