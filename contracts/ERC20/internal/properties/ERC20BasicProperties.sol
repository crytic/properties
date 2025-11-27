// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";

/**
 * @title ERC20 Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Core invariant properties for ERC20 token implementations
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 17 fundamental properties that test supply accounting,
 * @dev balance accounting, transfer mechanics, and allowance operations for ERC20 tokens.
 * @dev These properties represent the essential invariants that all ERC20 implementations
 * @dev should maintain to ensure correct accounting and safe operations.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyToken, CryticERC20BasicProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         _mint(USER2, INITIAL_BALANCE);
 * @dev         _mint(USER3, INITIAL_BALANCE);
 * @dev         initialSupply = totalSupply();
 * @dev         isMintableOrBurnable = false; // Set based on your token's features
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20BasicProperties is CryticERC20Base {
    constructor() {}


    /* ================================================================

                    SUPPLY ACCOUNTING PROPERTIES

       Description: Properties verifying total supply accounting correctness
       Testing Mode: INTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Constant Supply Invariant
    /// @notice For non-mintable/burnable tokens, total supply must remain constant
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: If `!isMintableOrBurnable`, then `totalSupply() == initialSupply` must always hold
    /// @dev This property only applies to tokens with fixed supply. For mintable or burnable
    /// @dev tokens, set `isMintableOrBurnable = true` to skip this check.
    /// @dev Preconditions: Only meaningful when isMintableOrBurnable is false
    /// @custom:property-id ERC20-SUPPLY-001
    function test_ERC20_constantSupply() public virtual {
        require(!isMintableOrBurnable);
        assertEq(initialSupply, totalSupply(), "Token supply was modified");
    }


    /* ================================================================

                    BALANCE ACCOUNTING PROPERTIES

       Description: Properties verifying individual balance accounting correctness
       Testing Mode: INTERNAL
       Property Count: 3

       ================================================================ */

    /// @title User Balance Cannot Exceed Total Supply
    /// @notice Ensures that any individual user's balance never exceeds the total token supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: For any address `user`, `balanceOf(user) <= totalSupply()` must always hold
    /// @dev This is a fundamental accounting invariant. If violated, the token contract has
    /// @dev a critical bug allowing token creation from nothing, double-counting, or overflow.
    /// @custom:property-id ERC20-BALANCE-001
    function test_ERC20_userBalanceNotHigherThanSupply() public {
        assertLte(
            balanceOf(msg.sender),
            totalSupply(),
            "User balance higher than total supply"
        );
    }

    /// @title Sum of User Balances Cannot Exceed Total Supply
    /// @notice Ensures that the sum of test user balances never exceeds the total supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `balanceOf(USER1) + balanceOf(USER2) + balanceOf(USER3) <= totalSupply()`
    /// @dev This checks that the accounting for multiple users remains consistent with total supply.
    /// @dev While not exhaustive (doesn't check all addresses), it provides confidence in multi-user scenarios.
    /// @custom:property-id ERC20-BALANCE-002
    function test_ERC20_usersBalancesNotHigherThanSupply() public {
        uint256 balance = balanceOf(USER1) +
            balanceOf(USER2) +
            balanceOf(USER3);
        assertLte(
            balance,
            totalSupply(),
            "Sum of user balances higher than total supply"
        );
    }

    /// @title Zero Address Has Zero Balance
    /// @notice The zero address should never hold tokens
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `balanceOf(address(0)) == 0` must always hold
    /// @dev The zero address (0x0) is conventionally used to represent burned tokens or null state.
    /// @dev If it holds a non-zero balance, tokens are effectively lost and inaccessible, breaking
    /// @dev the accounting assumption that all supply is either held by users or explicitly burned.
    /// @custom:property-id ERC20-BALANCE-003
    function test_ERC20_zeroAddressBalance() public {
        assertEq(
            balanceOf(address(0)),
            0,
            "Address zero balance not equal to zero"
        );
    }


    /* ================================================================

                    TRANSFER PROPERTIES

       Description: Properties verifying transfer mechanics and safety guarantees
       Testing Mode: INTERNAL
       Property Count: 10

       ================================================================ */

    /// @title Transfer to Zero Address Must Fail
    /// @notice Transfers to the zero address should not be allowed
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transfer(address(0), amount)` must return false or revert for any amount > 0
    /// @dev Prevents accidental token burning via transfer. Burning should use explicit burn()
    /// @dev functions if supported. This protects users from irreversible mistakes.
    /// @custom:property-id ERC20-TRANSFER-001
    function test_ERC20_transferToZeroAddress() public {
        uint256 balance = balanceOf(address(this));
        require(balance > 0);

        bool r = transfer(address(0), balance);
        assertWithMsg(r == false, "Successful transfer to address zero");
    }

    /// @title TransferFrom to Zero Address Must Fail
    /// @notice TransferFrom to the zero address should not be allowed
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transferFrom(sender, address(0), amount)` must return false or revert
    /// @dev Similar to direct transfers, this prevents accidental burning through delegated transfers.
    /// @dev Protects against both user error and potential exploits involving allowances.
    /// @custom:property-id ERC20-TRANSFER-002
    function test_ERC20_transferFromToZeroAddress(uint256 value) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > 0);
        uint256 maxValue = balance_sender >= current_allowance
            ? current_allowance
            : balance_sender;

        bool r = transferFrom(msg.sender, address(0), value % (maxValue + 1));
        assertWithMsg(r == false, "Successful transferFrom to address zero");
    }

    /// @title Self TransferFrom Preserves Balance
    /// @notice Transferring tokens to oneself via transferFrom should not change balance
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(user, user, amount)`, `balanceOf(user)` must remain unchanged
    /// @dev Self-transfers are a special case that some implementations handle incorrectly.
    /// @dev The balance should remain the same since tokens are both leaving and entering the same account.
    /// @custom:property-id ERC20-TRANSFER-003
    function test_ERC20_selfTransferFrom(uint256 value) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > 0);
        uint256 maxValue = balance_sender >= current_allowance
            ? current_allowance
            : balance_sender;

        bool r = transferFrom(msg.sender, msg.sender, value % (maxValue + 1));
        assertWithMsg(r == true, "Failed self transferFrom");
        assertEq(
            balance_sender,
            balanceOf(msg.sender),
            "Self transferFrom breaks accounting"
        );
    }

    /// @title Self Transfer Preserves Balance
    /// @notice Transferring tokens to oneself should not change balance
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transfer(sender, amount)` where sender == recipient, balance must be unchanged
    /// @dev Self-transfers via direct transfer() should behave identically to self transferFrom().
    /// @dev This is a common edge case that can expose accounting bugs in naive implementations.
    /// @custom:property-id ERC20-TRANSFER-004
    function test_ERC20_selfTransfer(uint256 value) public {
        uint256 balance_sender = balanceOf(address(this));
        require(balance_sender > 0);

        bool r = this.transfer(address(this), value % (balance_sender + 1));
        assertWithMsg(r == true, "Failed self transfer");
        assertEq(
            balance_sender,
            balanceOf(address(this)),
            "Self transfer breaks accounting"
        );
    }

    /// @title TransferFrom More Than Balance Must Fail
    /// @notice TransferFrom exceeding sender's balance should not be allowed
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transferFrom(sender, recipient, amount)` where `amount > balanceOf(sender)` must fail
    /// @dev Even with sufficient allowance, transfers cannot exceed the sender's actual balance.
    /// @dev Both sender and recipient balances must remain unchanged on failure.
    /// @custom:property-id ERC20-TRANSFER-005
    function test_ERC20_transferFromMoreThanBalance(address target) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);

        bool r = transferFrom(msg.sender, target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transferFrom for more than account balance"
        );
        assertEq(
            balanceOf(msg.sender),
            balance_sender,
            "TransferFrom for more than balance modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "TransferFrom for more than balance modified target balance"
        );
    }

    /// @title Transfer More Than Balance Must Fail
    /// @notice Transfers exceeding sender's balance should not be allowed
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transfer(recipient, amount)` where `amount > balanceOf(sender)` must fail
    /// @dev Fundamental safety property preventing token creation or negative balances.
    /// @dev Both sender and recipient balances must remain unchanged on failure.
    /// @custom:property-id ERC20-TRANSFER-006
    function test_ERC20_transferMoreThanBalance(address target) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 0);

        bool r = this.transfer(target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transfer for more than account balance"
        );
        assertEq(
            balanceOf(address(this)),
            balance_sender,
            "Transfer for more than balance modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Transfer for more than balance modified target balance"
        );
    }

    /// @title Zero Amount Transfer Succeeds Without Changes
    /// @notice Transferring zero tokens should succeed without modifying balances
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transfer(recipient, 0)` must succeed and leave all balances unchanged
    /// @dev Zero-value transfers should be no-ops. Some contracts incorrectly reject them,
    /// @dev which can break composability with other contracts expecting standard behavior.
    /// @custom:property-id ERC20-TRANSFER-007
    function test_ERC20_transferZeroAmount(address target) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 0);

        bool r = transfer(target, 0);
        assertWithMsg(r == true, "Zero amount transfer failed");
        assertEq(
            balanceOf(address(this)),
            balance_sender,
            "Zero amount transfer modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Zero amount transfer modified target balance"
        );
    }

    /// @title Zero Amount TransferFrom Succeeds Without Changes
    /// @notice TransferFrom with zero tokens should succeed without modifying balances
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transferFrom(sender, recipient, 0)` must succeed and leave balances unchanged
    /// @dev Zero-value delegated transfers should also be no-ops, maintaining consistency
    /// @dev with direct transfer behavior and ERC20 standard expectations.
    /// @custom:property-id ERC20-TRANSFER-008
    function test_ERC20_transferFromZeroAmount(address target) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > 0);

        bool r = transferFrom(msg.sender, target, 0);
        assertWithMsg(r == true, "Zero amount transferFrom failed");
        assertEq(
            balanceOf(msg.sender),
            balance_sender,
            "Zero amount transferFrom modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Zero amount transferFrom modified target balance"
        );
    }

    /// @title Transfer Updates Balances Correctly
    /// @notice Regular transfers should update sender and recipient balances correctly
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transfer(recipient, amount)`, sender balance decreases by `amount`
    /// @dev and recipient balance increases by `amount`
    /// @dev This is the core correctness property for transfers: tokens leaving one account
    /// @dev must arrive in the destination account, preserving total supply.
    /// @custom:property-id ERC20-TRANSFER-009
    function test_ERC20_transfer(address target, uint256 amount) public {
        require(target != address(this));
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 2);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = this.transfer(target, transfer_value);
        assertWithMsg(r == true, "transfer failed");
        assertEq(
            balanceOf(address(this)),
            balance_sender - transfer_value,
            "Wrong source balance after transfer"
        );
        assertEq(
            balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transfer"
        );
    }

    /// @title TransferFrom Updates Balances Correctly
    /// @notice Delegated transfers should update sender and recipient balances correctly
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(sender, recipient, amount)`, sender balance decreases
    /// @dev by `amount` and recipient balance increases by `amount`
    /// @dev Core correctness property for delegated transfers. Must maintain same accounting
    /// @dev guarantees as direct transfers, just with allowance consumption.
    /// @custom:property-id ERC20-TRANSFER-010
    function test_ERC20_transferFrom(address target, uint256 amount) public {
        require(target != address(this));
        require(target != msg.sender);
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 2 && current_allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transferFrom failed");
        assertEq(
            balanceOf(msg.sender),
            balance_sender - transfer_value,
            "Wrong source balance after transferFrom"
        );
        assertEq(
            balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transferFrom"
        );
    }


    /* ================================================================

                    ALLOWANCE PROPERTIES

       Description: Properties verifying approve/transferFrom allowance mechanics
       Testing Mode: INTERNAL
       Property Count: 3

       ================================================================ */

    /// @title Approve Sets Allowance Correctly
    /// @notice Approve should set the allowance to the specified amount
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `approve(spender, amount)`, `allowance(owner, spender) == amount`
    /// @dev Basic correctness property for the approval mechanism. The allowance value
    /// @dev must be set exactly as specified, enabling precise delegation of spending rights.
    /// @custom:property-id ERC20-ALLOWANCE-001
    function test_ERC20_setAllowance(address target, uint256 amount) public {
        bool r = this.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );
    }

    /// @title Approve Can Overwrite Previous Allowance
    /// @notice Approve should be able to change existing allowances
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: Sequential `approve()` calls should each set allowance to the new value
    /// @dev Allowances must be updateable to allow users to modify or revoke spending permissions.
    /// @dev This is essential for security (reducing allowances) and flexibility (increasing them).
    /// @custom:property-id ERC20-ALLOWANCE-002
    function test_ERC20_setAllowanceTwice(
        address target,
        uint256 amount
    ) public {
        bool r = this.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );

        r = this.approve(target, amount / 2);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            allowance(address(this), target),
            amount / 2,
            "Allowance not set correctly"
        );
    }

    /// @title TransferFrom Decreases Allowance
    /// @notice TransferFrom should decrease the allowance by the transferred amount
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(owner, recipient, amount)`, allowance decreases by `amount`
    /// @dev Exception: Allowance of `type(uint256).max` is treated as infinite by some implementations
    /// @dev This ensures that allowances are consumed correctly, preventing spenders from
    /// @dev exceeding their delegated permissions. The infinite allowance exception is a
    /// @dev common optimization to avoid storage updates for "unlimited" approvals.
    /// @custom:property-id ERC20-ALLOWANCE-003
    function test_ERC20_spendAllowanceAfterTransfer(
        address target,
        uint256 amount
    ) public {
        require(target != address(this) && target != address(0));
        require(target != msg.sender);
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = this.transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transferFrom failed");

        // Some implementations treat type(uint256).max as infinite allowance
        if (current_allowance != type(uint256).max) {
            assertEq(
                allowance(msg.sender, address(this)),
                current_allowance - transfer_value,
                "Allowance not updated correctly"
            );
        }
    }
}
