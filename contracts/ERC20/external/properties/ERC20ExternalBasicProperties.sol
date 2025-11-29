// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CryticERC20ExternalTestBase} from "../util/ERC20ExternalTestBase.sol";

/**
 * @title ERC20 External Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Core properties for ERC20 tokens tested via external interface
 * @dev Testing Mode: EXTERNAL (test harness interacts with token through external interface)
 * @dev This contract contains 18 properties that test fundamental ERC20 mechanics including
 * @dev supply invariants, balance constraints, transfer behavior, zero-value transfers,
 * @dev zero-address restrictions, self-transfers, and allowance management.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC20ExternalBasicProperties {
 * @dev     constructor() {
 * @dev         // Deploy or reference your ERC20 token
 * @dev         token = ITokenMock(address(new MyToken()));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20ExternalBasicProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}


    /* ================================================================

                        SUPPLY INVARIANT PROPERTIES

       Description: Properties verifying total supply consistency
       Testing Mode: EXTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Total Supply Must Remain Constant for Non-Mintable/Burnable Tokens
    /// @notice For tokens without mint/burn, total supply should never change
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: If token is not mintable or burnable, `totalSupply()` must always
    /// @dev equal `initialSupply`
    /// @dev This ensures that for fixed-supply tokens, no tokens can be created or destroyed
    /// @dev through any operation. Any deviation indicates unauthorized minting/burning or
    /// @dev accounting errors that violate the token's supply model.
    /// @custom:property-id ERC20-EXTERNAL-SUPPLY-001
    function test_ERC20external_constantSupply() public virtual {
        require(!token.isMintableOrBurnable());
        assertEq(
            token.initialSupply(),
            token.totalSupply(),
            "Token supply was modified"
        );
    }


    /* ================================================================

                        BALANCE CONSTRAINT PROPERTIES

       Description: Properties verifying balance vs supply relationships
       Testing Mode: EXTERNAL
       Property Count: 3

       ================================================================ */

    /// @title User Balance Cannot Exceed Total Supply
    /// @notice Individual balance must be less than or equal to total supply
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: For any address, `balanceOf(address)` <= `totalSupply()`
    /// @dev This fundamental invariant ensures no single account can hold more tokens than
    /// @dev exist in circulation. Violation indicates severe accounting errors or overflow bugs.
    /// @custom:property-id ERC20-EXTERNAL-BALANCE-001
    function test_ERC20external_userBalanceNotHigherThanSupply() public {
        assertLte(
            token.balanceOf(msg.sender),
            token.totalSupply(),
            "User balance higher than total supply"
        );
    }

    /// @title Sum of Balances Cannot Exceed Total Supply
    /// @notice Sum of tracked user balances must not exceed total supply
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `balanceOf(testContract) + balanceOf(USER1) + balanceOf(USER2) + balanceOf(USER3)`
    /// @dev <= `totalSupply()`
    /// @dev While we cannot check all accounts, verifying that even a subset of accounts
    /// @dev respects this invariant helps detect balance inflation bugs. The sum of any subset
    /// @dev of balances should never exceed the total supply.
    /// @custom:property-id ERC20-EXTERNAL-BALANCE-002
    function test_ERC20external_userBalancesLessThanTotalSupply() public {
        uint256 sumBalances = token.balanceOf(address(this)) +
            token.balanceOf(USER1) +
            token.balanceOf(USER2) +
            token.balanceOf(USER3);
        assertLte(
            sumBalances,
            token.totalSupply(),
            "Sum of user balances are greater than total supply"
        );
    }

    /// @title Zero Address Must Have Zero Balance
    /// @notice The zero address should never hold tokens
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `balanceOf(address(0))` must always equal 0
    /// @dev The zero address is commonly used for burning tokens. Maintaining a zero balance
    /// @dev for this address ensures burned tokens are truly removed from circulation rather
    /// @dev than being recoverable from address(0).
    /// @custom:property-id ERC20-EXTERNAL-BALANCE-003
    function test_ERC20external_zeroAddressBalance() public {
        assertEq(
            token.balanceOf(address(0)),
            0,
            "Address zero balance not equal to zero"
        );
    }


    /* ================================================================

                        ZERO ADDRESS TRANSFER PROPERTIES

       Description: Properties verifying zero address transfer restrictions
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Transfer to Zero Address Must Fail
    /// @notice Transfers to address(0) should not be allowed
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transfer(address(0), amount)` must return false or revert
    /// @dev Preventing transfers to the zero address protects users from accidentally burning
    /// @dev tokens. Many implementations explicitly check for and reject such transfers to
    /// @dev prevent irreversible loss of funds.
    /// @custom:property-id ERC20-EXTERNAL-ZERO-TRANSFER-001
    function test_ERC20external_transferToZeroAddress() public {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        bool r = token.transfer(address(0), balance);
        assertWithMsg(r == false, "Successful transfer to address zero");
    }

    /// @title TransferFrom to Zero Address Must Fail
    /// @notice Delegated transfers to address(0) should not be allowed
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transferFrom(owner, address(0), amount)` must return false or revert
    /// @dev Like direct transfers, delegated transfers to the zero address must also be blocked
    /// @dev to prevent accidental or malicious burning through the transferFrom mechanism.
    /// @custom:property-id ERC20-EXTERNAL-ZERO-TRANSFER-002
    function test_ERC20external_transferFromToZeroAddress(
        uint256 value
    ) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > 0);
        uint256 maxValue = balance_sender >= allowance
            ? allowance
            : balance_sender;

        bool r = token.transferFrom(
            msg.sender,
            address(0),
            value % (maxValue + 1)
        );
        assertWithMsg(r == false, "Successful transferFrom to address zero");
    }


    /* ================================================================

                        SELF TRANSFER PROPERTIES

       Description: Properties verifying self-transfer handling
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Self TransferFrom Must Not Break Accounting
    /// @notice Transferring tokens to oneself via transferFrom should succeed without changing balance
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(user, user, amount)`, `balanceOf(user)` remains unchanged
    /// @dev Self-transfers are edge cases that must be handled correctly. The balance should
    /// @dev remain the same since tokens are moved from an address to itself. Implementations
    /// @dev must handle this without underflow/overflow or other accounting errors.
    /// @custom:property-id ERC20-EXTERNAL-SELF-TRANSFER-001
    function test_ERC20external_selfTransferFrom(uint256 value) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > 0);
        uint256 maxValue = balance_sender >= allowance
            ? allowance
            : balance_sender;

        bool r = token.transferFrom(
            msg.sender,
            msg.sender,
            value % (maxValue + 1)
        );
        assertWithMsg(r == true, "Failed self transferFrom");
        assertEq(
            balance_sender,
            token.balanceOf(msg.sender),
            "Self transferFrom breaks accounting"
        );
    }

    /// @title Self Transfer Must Not Break Accounting
    /// @notice Transferring tokens to oneself should succeed without changing balance
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transfer(sender, amount)` where sender is msg.sender,
    /// @dev `balanceOf(sender)` remains unchanged
    /// @dev Like transferFrom, direct self-transfers must be handled correctly with no change
    /// @dev to the sender's balance. This tests proper handling of the edge case where source
    /// @dev and destination are identical.
    /// @custom:property-id ERC20-EXTERNAL-SELF-TRANSFER-002
    function test_ERC20external_selfTransfer(uint256 value) public {
        uint256 balance_sender = token.balanceOf(address(this));
        require(balance_sender > 0);

        bool r = token.transfer(address(this), value % (balance_sender + 1));
        assertWithMsg(r == true, "Failed self transfer");
        assertEq(
            balance_sender,
            token.balanceOf(address(this)),
            "Self transfer breaks accounting"
        );
    }


    /* ================================================================

                    INSUFFICIENT BALANCE TRANSFER PROPERTIES

       Description: Properties verifying transfer failures with insufficient balance
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title TransferFrom More Than Balance Must Fail
    /// @notice Attempting to transfer more than available balance should fail
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transferFrom(owner, recipient, balance + 1)` must return false or revert,
    /// @dev and both balances must remain unchanged
    /// @dev This ensures users cannot transfer more tokens than they own, preventing balance
    /// @dev underflow and maintaining accurate account balances across all operations.
    /// @custom:property-id ERC20-EXTERNAL-INSUFFICIENT-001
    function test_ERC20external_transferFromMoreThanBalance(
        address target
    ) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);

        bool r = token.transferFrom(msg.sender, target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transferFrom for more than account balance"
        );
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender,
            "TransferFrom for more than balance modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "TransferFrom for more than balance modified target balance"
        );
    }

    /// @title Transfer More Than Balance Must Fail
    /// @notice Attempting to transfer more than available balance should fail
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transfer(recipient, balance + 1)` must return false or revert,
    /// @dev and both balances must remain unchanged
    /// @dev Like transferFrom, direct transfers must also enforce the balance constraint
    /// @dev to prevent underflow and ensure conservation of tokens during transfers.
    /// @custom:property-id ERC20-EXTERNAL-INSUFFICIENT-002
    function test_ERC20external_transferMoreThanBalance(address target) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 0);

        bool r = token.transfer(target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transfer for more than account balance"
        );
        assertEq(
            token.balanceOf(address(this)),
            balance_sender,
            "Transfer for more than balance modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Transfer for more than balance modified target balance"
        );
    }


    /* ================================================================

                        ZERO AMOUNT TRANSFER PROPERTIES

       Description: Properties verifying zero-value transfer handling
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Zero Amount Transfer Must Not Change Balances
    /// @notice Transferring zero tokens should succeed without modifying balances
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transfer(recipient, 0)`, both sender and recipient balances
    /// @dev remain unchanged
    /// @dev Zero-value transfers are valid operations that should succeed without side effects.
    /// @dev This tests proper handling of edge cases and ensures no state changes occur for
    /// @dev meaningless transfers.
    /// @custom:property-id ERC20-EXTERNAL-ZERO-AMOUNT-001
    function test_ERC20external_transferZeroAmount(address target) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 0);

        bool r = token.transfer(target, 0);
        assertWithMsg(r == true, "Zero amount transfer failed");
        assertEq(
            token.balanceOf(address(this)),
            balance_sender,
            "Zero amount transfer modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Zero amount transfer modified target balance"
        );
    }

    /// @title Zero Amount TransferFrom Must Not Change Balances
    /// @notice Transferring zero tokens via transferFrom should succeed without modifying balances
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(owner, recipient, 0)`, both owner and recipient
    /// @dev balances remain unchanged
    /// @dev Like direct transfers, delegated zero-value transfers should succeed as no-ops.
    /// @dev This verifies consistent handling of zero-value operations across both transfer
    /// @dev mechanisms.
    /// @custom:property-id ERC20-EXTERNAL-ZERO-AMOUNT-002
    function test_ERC20external_transferFromZeroAmount(address target) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > 0);

        bool r = token.transferFrom(msg.sender, target, 0);
        assertWithMsg(r == true, "Zero amount transferFrom failed");
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender,
            "Zero amount transferFrom modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Zero amount transferFrom modified target balance"
        );
    }


    /* ================================================================

                        STANDARD TRANSFER PROPERTIES

       Description: Properties verifying correct transfer accounting
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Transfer Updates Balances Correctly
    /// @notice Successful transfers should decrease sender balance and increase recipient balance
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transfer(recipient, amount)`, sender balance decreases by `amount`
    /// @dev and recipient balance increases by `amount`
    /// @dev This is the core transfer property ensuring conservation of tokens. The exact amount
    /// @dev deducted from sender must be credited to recipient, with no tokens lost or created
    /// @dev during the transfer.
    /// @custom:property-id ERC20-EXTERNAL-TRANSFER-001
    function test_ERC20external_transfer(
        address target,
        uint256 amount
    ) public {
        require(target != address(this));
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 2);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = token.transfer(target, transfer_value);
        assertWithMsg(r == true, "transfer failed");
        assertEq(
            token.balanceOf(address(this)),
            balance_sender - transfer_value,
            "Wrong source balance after transfer"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transfer"
        );
    }

    /// @title TransferFrom Updates Balances Correctly
    /// @notice Successful delegated transfers should decrease owner balance and increase recipient balance
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(owner, recipient, amount)`, owner balance decreases
    /// @dev by `amount` and recipient balance increases by `amount`
    /// @dev Like direct transfers, delegated transfers must maintain conservation of tokens.
    /// @dev The spender facilitates the transfer but the accounting must remain accurate with
    /// @dev tokens moving directly from owner to recipient.
    /// @custom:property-id ERC20-EXTERNAL-TRANSFER-002
    function test_ERC20external_transferFrom(
        address target,
        uint256 amount
    ) public {
        require(target != address(this));
        require(target != msg.sender);
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 2 && allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = token.transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transfer failed");
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender - transfer_value,
            "Wrong source balance after transferFrom"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transferFrom"
        );
    }


    /* ================================================================

                        ALLOWANCE MANAGEMENT PROPERTIES

       Description: Properties verifying approve and allowance updates
       Testing Mode: EXTERNAL
       Property Count: 3

       ================================================================ */

    /// @title Approve Sets Allowance Correctly
    /// @notice Calling approve should set the allowance to the specified amount
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `approve(spender, amount)`, `allowance(owner, spender)` equals `amount`
    /// @dev The approve function is fundamental to the ERC20 allowance mechanism, enabling
    /// @dev delegated transfers. It must reliably set the allowance to the exact specified value.
    /// @custom:property-id ERC20-EXTERNAL-ALLOWANCE-001
    function test_ERC20external_setAllowance(
        address target,
        uint256 amount
    ) public {
        bool r = token.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );
    }

    /// @title Approve Can Overwrite Existing Allowance
    /// @notice Calling approve twice should update the allowance to the new value
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `approve(spender, amount1)` then `approve(spender, amount2)`,
    /// @dev `allowance(owner, spender)` equals `amount2`
    /// @dev The approve function must allow changing existing allowances. Users should be able
    /// @dev to revise permissions by calling approve again with a different amount.
    /// @custom:property-id ERC20-EXTERNAL-ALLOWANCE-002
    function test_ERC20external_setAllowanceTwice(
        address target,
        uint256 amount
    ) public {
        bool r = token.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );

        r = token.approve(target, amount / 2);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            amount / 2,
            "Allowance not set correctly"
        );
    }

    /// @title TransferFrom Consumes Allowance
    /// @notice Using transferFrom should decrease the spender's allowance
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(owner, recipient, amount)`, `allowance(owner, spender)`
    /// @dev decreases by `amount` (unless allowance is `type(uint256).max`)
    /// @dev Exception: Allowance of `type(uint256).max` is treated as infinite by some implementations
    /// @dev Consuming allowance during transferFrom prevents spenders from exceeding their
    /// @dev authorized amount. This property ensures the allowance mechanism properly limits
    /// @dev delegated transfer capabilities.
    /// @custom:property-id ERC20-EXTERNAL-ALLOWANCE-003
    function test_ERC20external_spendAllowanceAfterTransfer(
        address target,
        uint256 amount
    ) public {
        require(target != address(this) && target != address(0));
        require(target != msg.sender);
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 current_allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = token.transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transferFrom failed");

        // Some implementations take an allowance of 2**256-1 as infinite, and therefore don't update
        if (current_allowance != type(uint256).max) {
            assertEq(
                token.allowance(msg.sender, address(this)),
                current_allowance - transfer_value,
                "Allowance not updated correctly"
            );
        }
    }
}
