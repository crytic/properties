// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC1155TestBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ERC1155 Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Core invariant properties for ERC1155 multi-token implementations
 * @dev Testing Mode: INTERNAL
 * @dev This contract contains fundamental properties that must hold for any correct ERC1155
 * implementation. These properties test balance tracking, transfer operations, operator
 * approvals, batch operations, and safe transfer callbacks. The test contract inherits
 * from both the token implementation and this property contract, allowing direct access
 * to internal state.
 *
 * Properties are organized into the following sections:
 * - Balance Properties: Tests for balance queries and consistency
 * - Transfer Properties: Tests for single and batch transfers
 * - Approval Properties: Tests for operator approvals
 * - Safety Properties: Tests for safe transfer receiver checks
 *
 * @custom:see https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract CryticERC1155BasicProperties is CryticERC1155TestBase {
    using Address for address;

    ////////////////////////////////////////////////////////////////
    //                    Balance Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Balance of Zero Address
     * @notice The zero address should always have zero balance for all token IDs
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: balanceOf(address(0), id) == 0 for all id
     * @dev The zero address is commonly used to represent non-existent or burned tokens.
     * It should never hold any balance to prevent tokens from being lost permanently.
     * @custom:property-id ERC1155-BALANCE-001
     *
     * @param tokenId The token ID to check balance for
     */
    function test_ERC1155_zeroAddressBalance(uint256 tokenId) public {
        assertEq(
            balanceOf(address(0), tokenId),
            0,
            "Zero address has non-zero balance"
        );
    }

    /**
     * @title Batch Balance Consistency
     * @notice Batch balance queries must match individual balance queries
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: balanceOfBatch([addr1, addr2], [id1, id2]) == [balanceOf(addr1, id1), balanceOf(addr2, id2)]
     * @dev This ensures that the batch balance query function returns consistent results
     * with individual balance queries, which is critical for efficient multi-token operations.
     * @custom:property-id ERC1155-BALANCE-002
     *
     * @param tokenId Token ID to check balances for
     */
    function test_ERC1155_balanceOfBatchConsistency(uint256 tokenId) public {
        address[] memory accounts = new address[](3);
        accounts[0] = USER1;
        accounts[1] = USER2;
        accounts[2] = USER3;

        uint256[] memory ids = new uint256[](3);
        ids[0] = tokenId;
        ids[1] = tokenId;
        ids[2] = tokenId;

        uint256[] memory batchBalances = balanceOfBatch(accounts, ids);

        assertEq(
            batchBalances[0],
            balanceOf(USER1, tokenId),
            "Batch balance mismatch for USER1"
        );
        assertEq(
            batchBalances[1],
            balanceOf(USER2, tokenId),
            "Batch balance mismatch for USER2"
        );
        assertEq(
            batchBalances[2],
            balanceOf(USER3, tokenId),
            "Batch balance mismatch for USER3"
        );
    }

    ////////////////////////////////////////////////////////////////
    //                   Transfer Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Transfer to Zero Address Should Revert
     * @notice Transfers to the zero address must revert
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeTransferFrom(from, address(0), id, amount, data) must revert
     * @dev Preventing transfers to the zero address protects users from accidentally
     * burning tokens by sending them to an address from which they cannot be recovered.
     * @custom:property-id ERC1155-TRANSFER-001
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_transferToZeroAddress(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        safeTransferFrom(address(this), address(0), tokenId, transferAmount, "");
        assertWithMsg(false, "Transfer to zero address should have reverted");
    }

    /**
     * @title Transfer from Zero Address Should Revert
     * @notice Transfers from the zero address must revert
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeTransferFrom(address(0), to, id, amount, data) must revert
     * @dev The zero address should never be able to initiate transfers as it represents
     * non-existent or burned tokens.
     * @custom:property-id ERC1155-TRANSFER-002
     *
     * @param target The recipient address
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_transferFromZeroAddress(
        address target,
        uint256 tokenId,
        uint256 amount
    ) public {
        require(target != address(0));
        safeTransferFrom(address(0), target, tokenId, amount, "");
        assertWithMsg(false, "Transfer from zero address should have reverted");
    }

    /**
     * @title Transfer Updates Balances Correctly
     * @notice Transfers must correctly update sender and receiver balances
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: After safeTransferFrom(A, B, id, amount):
     *      - balanceOf(A, id) decreases by amount
     *      - balanceOf(B, id) increases by amount
     * @dev This fundamental property ensures conservation of tokens during transfers.
     * @custom:property-id ERC1155-TRANSFER-003
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_transferUpdatesBalances(uint256 tokenId, uint256 amount) public {
        uint256 senderBalance = balanceOf(address(this), tokenId);
        uint256 receiverBalance = balanceOf(USER1, tokenId);
        require(senderBalance > 0);
        require(USER1 != address(this));
        uint256 transferAmount = amount % (senderBalance + 1);

        this.safeTransferFrom(address(this), USER1, tokenId, transferAmount, "");

        assertEq(
            balanceOf(address(this), tokenId),
            senderBalance - transferAmount,
            "Sender balance not updated correctly"
        );
        assertEq(
            balanceOf(USER1, tokenId),
            receiverBalance + transferAmount,
            "Receiver balance not updated correctly"
        );
    }

    /**
     * @title Self Transfer Preserves Balance
     * @notice Transferring tokens to oneself should not change balance
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: balanceOf(A, id) before == balanceOf(A, id) after safeTransferFrom(A, A, id, amount)
     * @dev Self-transfers should be no-ops that don't break token accounting.
     * @custom:property-id ERC1155-TRANSFER-004
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_selfTransfer(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        this.safeTransferFrom(address(this), address(this), tokenId, transferAmount, "");

        assertEq(
            balanceOf(address(this), tokenId),
            balance,
            "Self transfer changed balance"
        );
    }

    /**
     * @title Batch Transfer Updates Balances Correctly
     * @notice Batch transfers must correctly update all balances
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeBatchTransferFrom must update all sender and receiver balances atomically
     * @dev Batch operations must maintain the same correctness guarantees as individual operations.
     * @custom:property-id ERC1155-TRANSFER-005
     *
     * @param tokenId1 First token ID to transfer
     * @param tokenId2 Second token ID to transfer
     * @param amount1 Amount of first token to transfer
     * @param amount2 Amount of second token to transfer
     */
    function test_ERC1155_batchTransferUpdatesBalances(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 amount1,
        uint256 amount2
    ) public {
        uint256 senderBalance1 = balanceOf(address(this), tokenId1);
        uint256 senderBalance2 = balanceOf(address(this), tokenId2);
        uint256 receiverBalance1 = balanceOf(USER1, tokenId1);
        uint256 receiverBalance2 = balanceOf(USER1, tokenId2);

        require(senderBalance1 > 0 && senderBalance2 > 0);
        require(USER1 != address(this));
        require(tokenId1 != tokenId2);

        uint256 transferAmount1 = amount1 % (senderBalance1 + 1);
        uint256 transferAmount2 = amount2 % (senderBalance2 + 1);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = transferAmount1;
        amounts[1] = transferAmount2;

        this.safeBatchTransferFrom(address(this), USER1, ids, amounts, "");

        assertEq(
            balanceOf(address(this), tokenId1),
            senderBalance1 - transferAmount1,
            "Sender balance 1 not updated correctly"
        );
        assertEq(
            balanceOf(address(this), tokenId2),
            senderBalance2 - transferAmount2,
            "Sender balance 2 not updated correctly"
        );
        assertEq(
            balanceOf(USER1, tokenId1),
            receiverBalance1 + transferAmount1,
            "Receiver balance 1 not updated correctly"
        );
        assertEq(
            balanceOf(USER1, tokenId2),
            receiverBalance2 + transferAmount2,
            "Receiver balance 2 not updated correctly"
        );
    }

    /**
     * @title Batch Transfer Array Length Mismatch Should Revert
     * @notice Batch transfer with mismatched array lengths must revert
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeBatchTransferFrom must revert if ids.length != amounts.length
     * @dev This prevents ambiguous batch operations and programming errors.
     * @custom:property-id ERC1155-TRANSFER-006
     */
    function test_ERC1155_batchTransferArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10;

        this.safeBatchTransferFrom(address(this), USER1, ids, amounts, "");
        assertWithMsg(false, "Batch transfer with mismatched arrays should have reverted");
    }

    ////////////////////////////////////////////////////////////////
    //                   Approval Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Set Approval for All
     * @notice Setting operator approval should update approval status
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: After setApprovalForAll(operator, true), isApprovedForAll(sender, operator) == true
     * @dev Operator approval allows efficient delegation of token management.
     * @custom:property-id ERC1155-APPROVAL-001
     *
     * @param operator The operator address to approve
     */
    function test_ERC1155_setApprovalForAll(address operator) public {
        require(operator != address(0));
        require(operator != address(this));

        this.setApprovalForAll(operator, true);
        assertWithMsg(
            isApprovedForAll(address(this), operator),
            "Operator not approved after setApprovalForAll(true)"
        );

        this.setApprovalForAll(operator, false);
        assertWithMsg(
            !isApprovedForAll(address(this), operator),
            "Operator still approved after setApprovalForAll(false)"
        );
    }

    /**
     * @title Operator Can Transfer on Behalf of Owner
     * @notice Approved operators must be able to transfer owner's tokens
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: If isApprovedForAll(owner, operator), then operator can call
     *      safeTransferFrom(owner, to, id, amount, data)
     * @dev This is the core functionality of operator approval.
     * @custom:property-id ERC1155-APPROVAL-002
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_operatorTransfer(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        require(USER1 != address(this));
        require(msg.sender != address(this));
        uint256 transferAmount = amount % (balance + 1);

        // Approve msg.sender as operator
        this.setApprovalForAll(msg.sender, true);
        require(isApprovedForAll(address(this), msg.sender));

        uint256 receiverBalance = balanceOf(USER1, tokenId);

        // msg.sender should be able to transfer tokens from address(this)
        hevm.prank(msg.sender);
        try
            IERC1155(address(this)).safeTransferFrom(
                address(this),
                USER1,
                tokenId,
                transferAmount,
                ""
            )
        {
            assertEq(
                balanceOf(address(this), tokenId),
                balance - transferAmount,
                "Owner balance not updated after operator transfer"
            );
            assertEq(
                balanceOf(USER1, tokenId),
                receiverBalance + transferAmount,
                "Receiver balance not updated after operator transfer"
            );
        } catch {
            assertWithMsg(false, "Operator transfer unexpectedly reverted");
        }
    }

    /**
     * @title Non-Operator Cannot Transfer
     * @notice Non-approved addresses must not be able to transfer tokens
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: If !isApprovedForAll(owner, operator) and operator != owner,
     *      then operator cannot call safeTransferFrom(owner, to, id, amount, data)
     * @dev This ensures that only authorized parties can move tokens.
     * @custom:property-id ERC1155-APPROVAL-003
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_nonOperatorCannotTransfer(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        require(msg.sender != address(this));
        require(USER1 != address(this));
        uint256 transferAmount = amount % (balance + 1);

        // Ensure msg.sender is not an operator
        this.setApprovalForAll(msg.sender, false);
        require(!isApprovedForAll(address(this), msg.sender));

        // msg.sender should NOT be able to transfer tokens from address(this)
        hevm.prank(msg.sender);
        IERC1155(address(this)).safeTransferFrom(
            address(this),
            USER1,
            tokenId,
            transferAmount,
            ""
        );

        assertWithMsg(false, "Non-operator transfer should have reverted");
    }

    ////////////////////////////////////////////////////////////////
    //                    Safety Properties                       //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Safe Transfer to Contract Without Receiver
     * @notice Safe transfers to contracts not implementing the receiver interface must revert
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeTransferFrom to a contract that doesn't implement
     *      onERC1155Received must revert
     * @dev This protects against tokens being permanently locked in contracts.
     * @custom:property-id ERC1155-SAFETY-001
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_safeTransferToNonReceiverContract(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        // unsafeReceiver returns wrong selector
        this.safeTransferFrom(
            address(this),
            address(unsafeReceiver),
            tokenId,
            transferAmount,
            ""
        );

        assertWithMsg(
            false,
            "Safe transfer to non-receiver contract should have reverted"
        );
    }

    /**
     * @title Safe Transfer to Valid Receiver
     * @notice Safe transfers to contracts implementing the receiver interface must succeed
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeTransferFrom to a contract implementing onERC1155Received
     *      correctly should succeed
     * @dev This ensures that properly implemented receiver contracts can accept tokens.
     * @custom:property-id ERC1155-SAFETY-002
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_safeTransferToValidReceiver(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        uint256 receiverBalance = balanceOf(address(safeReceiver), tokenId);

        this.safeTransferFrom(
            address(this),
            address(safeReceiver),
            tokenId,
            transferAmount,
            ""
        );

        assertEq(
            balanceOf(address(safeReceiver), tokenId),
            receiverBalance + transferAmount,
            "Safe receiver did not receive tokens"
        );
    }

    /**
     * @title Safe Batch Transfer to Contract Without Receiver
     * @notice Safe batch transfers to contracts not implementing the receiver interface must revert
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: safeBatchTransferFrom to a contract that doesn't implement
     *      onERC1155BatchReceived must revert
     * @dev This protects against tokens being permanently locked in contracts during batch operations.
     * @custom:property-id ERC1155-SAFETY-003
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155_safeBatchTransferToNonReceiverContract(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = transferAmount;

        this.safeBatchTransferFrom(
            address(this),
            address(unsafeReceiver),
            ids,
            amounts,
            ""
        );

        assertWithMsg(
            false,
            "Safe batch transfer to non-receiver contract should have reverted"
        );
    }
}
