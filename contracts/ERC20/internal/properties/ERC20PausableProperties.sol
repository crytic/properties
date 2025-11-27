// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title ERC20 Pausable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with pause functionality
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 2 properties that test pause/unpause mechanics,
 * @dev ensuring transfers are blocked when the contract is paused.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyPausableToken, CryticERC20PausableProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         _mint(USER2, INITIAL_BALANCE);
 * @dev         _mint(USER3, INITIAL_BALANCE);
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20PausableProperties is
    CryticERC20Base,
    ERC20Pausable
{
    constructor() {}

    // ================================================================
    // HELPER FUNCTIONS
    // ================================================================

    /// @notice Helper function to set pause state
    /// @dev May need tweaking for non-OpenZeppelin tokens with different pause mechanisms
    function _overridePause(bool paused) internal {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice Override for pausable tokens to ensure proper hook execution
    /// @dev Required to properly integrate OpenZeppelin's pausable mechanism
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }


    /* ================================================================

                        PAUSE PROPERTIES

       Description: Properties verifying pause/unpause mechanics
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Transfer Must Fail When Paused
    /// @notice Direct transfers should be blocked when contract is paused
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: When paused, `transfer(recipient, amount)` must return false or revert,
    /// @dev and balances must remain unchanged
    /// @dev The pause mechanism is a critical safety feature allowing contract administrators
    /// @dev to halt all token transfers in emergency situations. This property ensures the pause
    /// @dev works correctly by preventing any balance changes while paused.
    /// @custom:property-id ERC20-PAUSE-001
    function test_ERC20_pausedTransfer(address target, uint256 amount) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 0);
        uint256 transfer_amount = amount % (balance_sender + 1);

        _pause();

        bool r = this.transfer(target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(
            balanceOf(address(this)),
            balance_sender,
            "Transfer while paused altered source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Transfer while paused altered target balance"
        );

        _unpause();
    }

    /// @title TransferFrom Must Fail When Paused
    /// @notice Delegated transfers should be blocked when contract is paused
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: When paused, `transferFrom(owner, recipient, amount)` must return false
    /// @dev or revert, and balances must remain unchanged
    /// @dev Like direct transfers, delegated transfers via transferFrom must also be blocked
    /// @dev during pause. This ensures complete halt of all token movements regardless of
    /// @dev transfer method, maintaining pause integrity across all transfer mechanisms.
    /// @custom:property-id ERC20-PAUSE-002
    function test_ERC20_pausedTransferFrom(
        address target,
        uint256 amount
    ) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 transfer_amount = amount % (balance_sender + 1);

        _pause();

        bool r = this.transferFrom(msg.sender, target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(
            balanceOf(msg.sender),
            balance_sender,
            "Transfer while paused altered source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Transfer while paused altered target balance"
        );

        _unpause();
    }
}
