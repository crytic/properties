// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {CryticERC1155ExternalTestBase} from "../util/ERC1155ExternalTestBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ERC1155 External Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Core invariant properties for ERC1155 multi-token implementations tested externally
 * @dev Testing Mode: EXTERNAL
 * @dev This contract contains fundamental properties that must hold for any correct ERC1155
 * implementation. These properties test the token through its external interface only,
 * without inheriting from the implementation. This approach is useful for testing
 * deployed contracts or implementations that cannot be easily inherited.
 *
 * Properties are organized into the following sections:
 * - Balance Properties: Tests for balance queries and consistency
 * - Transfer Properties: Tests for single and batch transfers
 * - Approval Properties: Tests for operator approvals
 * - Safety Properties: Tests for safe transfer receiver checks
 *
 * @custom:see https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract CryticERC1155ExternalBasicProperties is
    CryticERC1155ExternalTestBase
{
    using Address for address;

    ////////////////////////////////////////////////////////////////
    //                    Balance Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Balance of Zero Address
     * @notice The zero address should always have zero balance for all token IDs
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: balanceOf(address(0), id) == 0 for all id
     * @dev The zero address is commonly used to represent non-existent or burned tokens.
     * It should never hold any balance to prevent tokens from being lost permanently.
     * @custom:property-id ERC1155-EXTERNAL-BALANCE-051
     *
     * @param tokenId The token ID to check balance for
     */
    function test_ERC1155external_zeroAddressBalance(uint256 tokenId) public {
        assertEq(
            token.balanceOf(address(0), tokenId),
            0,
            "Zero address has non-zero balance"
        );
    }

    /**
     * @title Batch Balance Consistency
     * @notice Batch balance queries must match individual balance queries
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: balanceOfBatch([addr1, addr2], [id1, id2]) == [balanceOf(addr1, id1), balanceOf(addr2, id2)]
     * @dev This ensures that the batch balance query function returns consistent results
     * with individual balance queries, which is critical for efficient multi-token operations.
     * @custom:property-id ERC1155-EXTERNAL-BALANCE-052
     *
     * @param tokenId Token ID to check balances for
     */
    function test_ERC1155external_balanceOfBatchConsistency(
        uint256 tokenId
    ) public {
        address[] memory accounts = new address[](3);
        accounts[0] = USER1;
        accounts[1] = USER2;
        accounts[2] = USER3;

        uint256[] memory ids = new uint256[](3);
        ids[0] = tokenId;
        ids[1] = tokenId;
        ids[2] = tokenId;

        uint256[] memory batchBalances = token.balanceOfBatch(accounts, ids);

        assertEq(
            batchBalances[0],
            token.balanceOf(USER1, tokenId),
            "Batch balance mismatch for USER1"
        );
        assertEq(
            batchBalances[1],
            token.balanceOf(USER2, tokenId),
            "Batch balance mismatch for USER2"
        );
        assertEq(
            batchBalances[2],
            token.balanceOf(USER3, tokenId),
            "Batch balance mismatch for USER3"
        );
    }

    ////////////////////////////////////////////////////////////////
    //                   Transfer Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Transfer to Zero Address Should Revert
     * @notice Transfers to the zero address must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeTransferFrom(from, address(0), id, amount, data) must revert
     * @dev Preventing transfers to the zero address protects users from accidentally
     * burning tokens by sending them to an address from which they cannot be recovered.
     * @custom:property-id ERC1155-EXTERNAL-TRANSFER-051
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_transferToZeroAddress(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        token.safeTransferFrom(
            address(this),
            address(0),
            tokenId,
            transferAmount,
            ""
        );
        assertWithMsg(false, "Transfer to zero address should have reverted");
    }

    /**
     * @title Transfer from Zero Address Should Revert
     * @notice Transfers from the zero address must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeTransferFrom(address(0), to, id, amount, data) must revert
     * @dev The zero address should never be able to initiate transfers as it represents
     * non-existent or burned tokens.
     * @custom:property-id ERC1155-EXTERNAL-TRANSFER-052
     *
     * @param target The recipient address
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_transferFromZeroAddress(
        address target,
        uint256 tokenId,
        uint256 amount
    ) public {
        require(target != address(0));
        token.safeTransferFrom(address(0), target, tokenId, amount, "");
        assertWithMsg(false, "Transfer from zero address should have reverted");
    }

    /**
     * @title Transfer Updates Balances Correctly
     * @notice Transfers must correctly update sender and receiver balances
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: After safeTransferFrom(A, B, id, amount):
     *      - balanceOf(A, id) decreases by amount
     *      - balanceOf(B, id) increases by amount
     * @dev This fundamental property ensures conservation of tokens during transfers.
     * @custom:property-id ERC1155-EXTERNAL-TRANSFER-053
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_transferUpdatesBalances(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 senderBalance = token.balanceOf(address(this), tokenId);
        uint256 receiverBalance = token.balanceOf(USER1, tokenId);
        require(senderBalance > 0);
        require(USER1 != address(this));
        uint256 transferAmount = amount % (senderBalance + 1);

        token.safeTransferFrom(
            address(this),
            USER1,
            tokenId,
            transferAmount,
            ""
        );

        assertEq(
            token.balanceOf(address(this), tokenId),
            senderBalance - transferAmount,
            "Sender balance not updated correctly"
        );
        assertEq(
            token.balanceOf(USER1, tokenId),
            receiverBalance + transferAmount,
            "Receiver balance not updated correctly"
        );
    }

    /**
     * @title Self Transfer Preserves Balance
     * @notice Transferring tokens to oneself should not change balance
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: balanceOf(A, id) before == balanceOf(A, id) after safeTransferFrom(A, A, id, amount)
     * @dev Self-transfers should be no-ops that don't break token accounting.
     * @custom:property-id ERC1155-EXTERNAL-TRANSFER-054
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_selfTransfer(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        token.safeTransferFrom(
            address(this),
            address(this),
            tokenId,
            transferAmount,
            ""
        );

        assertEq(
            token.balanceOf(address(this), tokenId),
            balance,
            "Self transfer changed balance"
        );
    }

    /**
     * @title Batch Transfer Updates Balances Correctly
     * @notice Batch transfers must correctly update all balances
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeBatchTransferFrom must update all sender and receiver balances atomically
     * @dev Batch operations must maintain the same correctness guarantees as individual operations.
     * @custom:property-id ERC1155-EXTERNAL-TRANSFER-055
     *
     * @param tokenId1 First token ID to transfer
     * @param tokenId2 Second token ID to transfer
     * @param amount1 Amount of first token to transfer
     * @param amount2 Amount of second token to transfer
     */
    function test_ERC1155external_batchTransferUpdatesBalances(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 amount1,
        uint256 amount2
    ) public {
        uint256 senderBalance1 = token.balanceOf(address(this), tokenId1);
        uint256 senderBalance2 = token.balanceOf(address(this), tokenId2);
        uint256 receiverBalance1 = token.balanceOf(USER1, tokenId1);
        uint256 receiverBalance2 = token.balanceOf(USER1, tokenId2);

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

        token.safeBatchTransferFrom(address(this), USER1, ids, amounts, "");

        assertEq(
            token.balanceOf(address(this), tokenId1),
            senderBalance1 - transferAmount1,
            "Sender balance 1 not updated correctly"
        );
        assertEq(
            token.balanceOf(address(this), tokenId2),
            senderBalance2 - transferAmount2,
            "Sender balance 2 not updated correctly"
        );
        assertEq(
            token.balanceOf(USER1, tokenId1),
            receiverBalance1 + transferAmount1,
            "Receiver balance 1 not updated correctly"
        );
        assertEq(
            token.balanceOf(USER1, tokenId2),
            receiverBalance2 + transferAmount2,
            "Receiver balance 2 not updated correctly"
        );
    }

    /**
     * @title Batch Transfer Array Length Mismatch Should Revert
     * @notice Batch transfer with mismatched array lengths must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeBatchTransferFrom must revert if ids.length != amounts.length
     * @dev This prevents ambiguous batch operations and programming errors.
     * @custom:property-id ERC1155-EXTERNAL-TRANSFER-056
     */
    function test_ERC1155external_batchTransferArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10;

        token.safeBatchTransferFrom(address(this), USER1, ids, amounts, "");
        assertWithMsg(
            false,
            "Batch transfer with mismatched arrays should have reverted"
        );
    }

    ////////////////////////////////////////////////////////////////
    //                   Approval Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Set Approval for All
     * @notice Setting operator approval should update approval status
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: After setApprovalForAll(operator, true), isApprovedForAll(sender, operator) == true
     * @dev Operator approval allows efficient delegation of token management.
     * @custom:property-id ERC1155-EXTERNAL-APPROVAL-051
     *
     * @param operator The operator address to approve
     */
    function test_ERC1155external_setApprovalForAll(address operator) public {
        require(operator != address(0));
        require(operator != address(this));

        token.setApprovalForAll(operator, true);
        assertWithMsg(
            token.isApprovedForAll(address(this), operator),
            "Operator not approved after setApprovalForAll(true)"
        );

        token.setApprovalForAll(operator, false);
        assertWithMsg(
            !token.isApprovedForAll(address(this), operator),
            "Operator still approved after setApprovalForAll(false)"
        );
    }

    /**
     * @title Non-Operator Cannot Transfer
     * @notice Non-approved addresses must not be able to transfer tokens
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: If !isApprovedForAll(owner, operator) and operator != owner,
     *      then operator cannot call safeTransferFrom(owner, to, id, amount, data)
     * @dev This ensures that only authorized parties can move tokens.
     * @custom:property-id ERC1155-EXTERNAL-APPROVAL-052
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_nonOperatorCannotTransfer(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        require(msg.sender != address(this));
        require(USER1 != address(this));
        uint256 transferAmount = amount % (balance + 1);

        // Ensure msg.sender is not an operator
        token.setApprovalForAll(msg.sender, false);
        require(!token.isApprovedForAll(address(this), msg.sender));

        // msg.sender should NOT be able to transfer tokens from address(this)
        hevm.prank(msg.sender);
        token.safeTransferFrom(
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
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeTransferFrom to a contract that doesn't implement
     *      onERC1155Received must revert
     * @dev This protects against tokens being permanently locked in contracts.
     * @custom:property-id ERC1155-EXTERNAL-SAFETY-051
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_safeTransferToNonReceiverContract(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        // unsafeReceiver returns wrong selector
        token.safeTransferFrom(
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
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeTransferFrom to a contract implementing onERC1155Received
     *      correctly should succeed
     * @dev This ensures that properly implemented receiver contracts can accept tokens.
     * @custom:property-id ERC1155-EXTERNAL-SAFETY-052
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_safeTransferToValidReceiver(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        uint256 receiverBalance = token.balanceOf(
            address(safeReceiver),
            tokenId
        );

        token.safeTransferFrom(
            address(this),
            address(safeReceiver),
            tokenId,
            transferAmount,
            ""
        );

        assertEq(
            token.balanceOf(address(safeReceiver), tokenId),
            receiverBalance + transferAmount,
            "Safe receiver did not receive tokens"
        );
    }

    /**
     * @title Safe Batch Transfer to Contract Without Receiver
     * @notice Safe batch transfers to contracts not implementing the receiver interface must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: safeBatchTransferFrom to a contract that doesn't implement
     *      onERC1155BatchReceived must revert
     * @dev This protects against tokens being permanently locked in contracts during batch operations.
     * @custom:property-id ERC1155-EXTERNAL-SAFETY-053
     *
     * @param tokenId The token ID to transfer
     * @param amount The amount to transfer
     */
    function test_ERC1155external_safeBatchTransferToNonReceiverContract(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 transferAmount = amount % (balance + 1);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = transferAmount;

        token.safeBatchTransferFrom(
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
