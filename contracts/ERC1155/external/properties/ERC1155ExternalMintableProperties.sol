// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {CryticERC1155ExternalTestBase} from "../util/ERC1155ExternalTestBase.sol";

/**
 * @title ERC1155 External Mintable Properties
 * @author Crytic (Trail of Bits)
 * @notice Invariant properties for ERC1155 tokens with mint functionality tested externally
 * @dev Testing Mode: EXTERNAL
 * @dev This contract contains properties that must hold for ERC1155 implementations
 * with mint functionality. These properties test the token through its external
 * interface only, ensuring that minting tokens correctly increases balances for
 * both single and batch operations.
 *
 * Properties are organized into the following sections:
 * - Mint Properties: Tests for single token mint operations
 * - Batch Mint Properties: Tests for batch mint operations
 *
 * Note: The mint functions must be implemented by the inheriting contract as
 * different implementations may have different access control or minting logic.
 *
 * @custom:see https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract CryticERC1155ExternalMintableProperties is
    CryticERC1155ExternalTestBase
{
    // Interface for mint functions - must be implemented by the inheriting contract
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual;

    ////////////////////////////////////////////////////////////////
    //                     Mint Properties                        //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Mint Increases Balance
     * @notice Minting tokens must increase the recipient's balance by the mint amount
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: After mint(to, id, amount, data), balanceOf(to, id) increases by amount
     * @dev Mint operations must correctly update token balances to maintain accurate accounting.
     * @custom:property-id ERC1155-EXTERNAL-MINT-051
     *
     * @param target The address to mint tokens to
     * @param tokenId The token ID to mint
     * @param amount The amount to mint
     */
    function test_ERC1155external_mintIncreasesBalance(
        address target,
        uint256 tokenId,
        uint256 amount
    ) public {
        require(target != address(0));
        uint256 balance = token.balanceOf(target, tokenId);

        this.mint(target, tokenId, amount, "");

        assertEq(
            token.balanceOf(target, tokenId),
            balance + amount,
            "Balance not increased correctly after mint"
        );
    }

    /**
     * @title Mint to Zero Address Should Revert
     * @notice Minting tokens to the zero address must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: mint(address(0), id, amount, data) must revert
     * @dev Minting to the zero address would effectively burn tokens at creation,
     * which is inconsistent and should be prevented.
     * @custom:property-id ERC1155-EXTERNAL-MINT-052
     *
     * @param tokenId The token ID to mint
     * @param amount The amount to mint
     */
    function test_ERC1155external_mintToZeroAddress(
        uint256 tokenId,
        uint256 amount
    ) public {
        this.mint(address(0), tokenId, amount, "");
        assertWithMsg(false, "Mint to zero address should have reverted");
    }

    /**
     * @title Mint Respects Safe Transfer Check
     * @notice Minting to a contract must respect the receiver interface check
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: If recipient is a contract, mint must call onERC1155Received
     *      and revert if the contract doesn't return the correct selector
     * @dev This protects against tokens being locked in contracts that can't handle them.
     * @custom:property-id ERC1155-EXTERNAL-MINT-053
     *
     * @param tokenId The token ID to mint
     * @param amount The amount to mint
     */
    function test_ERC1155external_mintToNonReceiverContract(
        uint256 tokenId,
        uint256 amount
    ) public {
        require(amount > 0);

        // unsafeReceiver returns wrong selector
        this.mint(address(unsafeReceiver), tokenId, amount, "");

        assertWithMsg(false, "Mint to non-receiver contract should have reverted");
    }

    /**
     * @title Mint to Valid Receiver Succeeds
     * @notice Minting to a contract implementing the receiver interface must succeed
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: mint to a contract implementing onERC1155Received correctly should succeed
     * @dev This ensures that properly implemented receiver contracts can receive minted tokens.
     * @custom:property-id ERC1155-EXTERNAL-MINT-054
     *
     * @param tokenId The token ID to mint
     * @param amount The amount to mint
     */
    function test_ERC1155external_mintToValidReceiver(
        uint256 tokenId,
        uint256 amount
    ) public {
        require(amount > 0);
        uint256 receiverBalance = token.balanceOf(
            address(safeReceiver),
            tokenId
        );

        this.mint(address(safeReceiver), tokenId, amount, "");

        assertEq(
            token.balanceOf(address(safeReceiver), tokenId),
            receiverBalance + amount,
            "Safe receiver did not receive minted tokens"
        );
    }

    ////////////////////////////////////////////////////////////////
    //                 Batch Mint Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Batch Mint Increases All Balances
     * @notice Minting multiple tokens in a batch must increase all balances correctly
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: After mintBatch(to, ids, amounts, data), all corresponding
     *      balances increase by the specified amounts
     * @dev Batch operations must maintain the same correctness as individual operations.
     * @custom:property-id ERC1155-EXTERNAL-MINT-055
     *
     * @param target The address to mint tokens to
     * @param tokenId1 First token ID to mint
     * @param tokenId2 Second token ID to mint
     * @param amount1 Amount of first token to mint
     * @param amount2 Amount of second token to mint
     */
    function test_ERC1155external_batchMintIncreasesBalances(
        address target,
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 amount1,
        uint256 amount2
    ) public {
        require(target != address(0));
        require(tokenId1 != tokenId2);

        uint256 balance1 = token.balanceOf(target, tokenId1);
        uint256 balance2 = token.balanceOf(target, tokenId2);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount1;
        amounts[1] = amount2;

        this.mintBatch(target, ids, amounts, "");

        assertEq(
            token.balanceOf(target, tokenId1),
            balance1 + amount1,
            "Balance 1 not increased correctly after batch mint"
        );
        assertEq(
            token.balanceOf(target, tokenId2),
            balance2 + amount2,
            "Balance 2 not increased correctly after batch mint"
        );
    }

    /**
     * @title Batch Mint Array Length Mismatch Should Revert
     * @notice Batch mint with mismatched array lengths must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: mintBatch must revert if ids.length != amounts.length
     * @dev This prevents ambiguous batch operations and programming errors.
     * @custom:property-id ERC1155-EXTERNAL-MINT-056
     *
     * @param target The address to mint tokens to
     */
    function test_ERC1155external_batchMintArrayLengthMismatch(
        address target
    ) public {
        require(target != address(0));

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10;

        this.mintBatch(target, ids, amounts, "");
        assertWithMsg(
            false,
            "Batch mint with mismatched arrays should have reverted"
        );
    }

    /**
     * @title Batch Mint to Zero Address Should Revert
     * @notice Batch minting tokens to the zero address must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: mintBatch(address(0), ids, amounts, data) must revert
     * @dev This maintains consistency with single mint operations.
     * @custom:property-id ERC1155-EXTERNAL-MINT-057
     *
     * @param tokenId The token ID to mint
     * @param amount The amount to mint
     */
    function test_ERC1155external_batchMintToZeroAddress(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        this.mintBatch(address(0), ids, amounts, "");
        assertWithMsg(false, "Batch mint to zero address should have reverted");
    }

    /**
     * @title Batch Mint Respects Safe Transfer Check
     * @notice Batch minting to a contract must respect the receiver interface check
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: If recipient is a contract, mintBatch must call onERC1155BatchReceived
     *      and revert if the contract doesn't return the correct selector
     * @dev This protects against tokens being locked in contracts during batch operations.
     * @custom:property-id ERC1155-EXTERNAL-MINT-058
     *
     * @param tokenId The token ID to mint
     * @param amount The amount to mint
     */
    function test_ERC1155external_batchMintToNonReceiverContract(
        uint256 tokenId,
        uint256 amount
    ) public {
        require(amount > 0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // unsafeReceiver returns wrong selector
        this.mintBatch(address(unsafeReceiver), ids, amounts, "");

        assertWithMsg(
            false,
            "Batch mint to non-receiver contract should have reverted"
        );
    }
}
