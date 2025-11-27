// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {CryticERC1155ExternalTestBase} from "../util/ERC1155ExternalTestBase.sol";

/**
 * @title ERC1155 External Burnable Properties
 * @author Crytic (Trail of Bits)
 * @notice Invariant properties for ERC1155 tokens with burn functionality tested externally
 * @dev Testing Mode: EXTERNAL
 * @dev This contract contains properties that must hold for ERC1155 implementations
 * with burn functionality. These properties test the token through its external
 * interface only, ensuring that burning tokens correctly reduces balances and
 * respects authorization requirements.
 *
 * Properties are organized into the following sections:
 * - Burn Properties: Tests for single token burn operations
 * - Batch Burn Properties: Tests for batch burn operations
 *
 * @custom:see https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract CryticERC1155ExternalBurnableProperties is
    CryticERC1155ExternalTestBase
{
    // Interface for burn functions - must be implemented by the external token
    function burn(address account, uint256 id, uint256 amount) public virtual;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual;

    ////////////////////////////////////////////////////////////////
    //                     Burn Properties                        //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Burn Reduces Balance
     * @notice Burning tokens must reduce the owner's balance by the burn amount
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: After burn(account, id, amount), balanceOf(account, id) decreases by amount
     * @dev Burn operations must correctly update token balances to maintain accurate accounting.
     * @custom:property-id ERC1155-EXTERNAL-BURN-051
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155external_burnReducesBalance(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 burnAmount = amount % (balance + 1);

        this.burn(address(this), tokenId, burnAmount);

        assertEq(
            token.balanceOf(address(this), tokenId),
            balance - burnAmount,
            "Balance not reduced correctly after burn"
        );
    }

    /**
     * @title Burn from Another Account Requires Approval
     * @notice Burning tokens from another account requires operator approval
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: If !isApprovedForAll(account, operator) and operator != account,
     *      then burn(account, id, amount) called by operator must revert
     * @dev This prevents unauthorized token destruction.
     * @custom:property-id ERC1155-EXTERNAL-BURN-052
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155external_burnRequiresApproval(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(USER1, tokenId);
        require(balance > 0);
        require(msg.sender != USER1);
        require(msg.sender != address(this));
        uint256 burnAmount = amount % (balance + 1);

        // Ensure msg.sender is not approved
        hevm.prank(USER1);
        token.setApprovalForAll(msg.sender, false);
        require(!token.isApprovedForAll(USER1, msg.sender));

        // msg.sender should NOT be able to burn USER1's tokens
        hevm.prank(msg.sender);
        this.burn(USER1, tokenId, burnAmount);

        assertWithMsg(false, "Burn without approval should have reverted");
    }

    ////////////////////////////////////////////////////////////////
    //                 Batch Burn Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Batch Burn Reduces All Balances
     * @notice Burning multiple tokens in a batch must reduce all balances correctly
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: After burnBatch(account, ids, amounts), all corresponding
     *      balances decrease by the specified amounts
     * @dev Batch operations must maintain the same correctness as individual operations.
     * @custom:property-id ERC1155-EXTERNAL-BURN-053
     *
     * @param tokenId1 First token ID to burn
     * @param tokenId2 Second token ID to burn
     * @param amount1 Amount of first token to burn
     * @param amount2 Amount of second token to burn
     */
    function test_ERC1155external_batchBurnReducesBalances(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 amount1,
        uint256 amount2
    ) public {
        uint256 balance1 = token.balanceOf(address(this), tokenId1);
        uint256 balance2 = token.balanceOf(address(this), tokenId2);
        require(balance1 > 0 && balance2 > 0);
        require(tokenId1 != tokenId2);

        uint256 burnAmount1 = amount1 % (balance1 + 1);
        uint256 burnAmount2 = amount2 % (balance2 + 1);

        uint256[] memory ids = new uint256[](2);
        ids[0] = tokenId1;
        ids[1] = tokenId2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = burnAmount1;
        amounts[1] = burnAmount2;

        this.burnBatch(address(this), ids, amounts);

        assertEq(
            token.balanceOf(address(this), tokenId1),
            balance1 - burnAmount1,
            "Balance 1 not reduced correctly after batch burn"
        );
        assertEq(
            token.balanceOf(address(this), tokenId2),
            balance2 - burnAmount2,
            "Balance 2 not reduced correctly after batch burn"
        );
    }

    /**
     * @title Batch Burn Array Length Mismatch Should Revert
     * @notice Batch burn with mismatched array lengths must revert
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: burnBatch must revert if ids.length != amounts.length
     * @dev This prevents ambiguous batch operations and programming errors.
     * @custom:property-id ERC1155-EXTERNAL-BURN-054
     */
    function test_ERC1155external_batchBurnArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10;

        this.burnBatch(address(this), ids, amounts);
        assertWithMsg(
            false,
            "Batch burn with mismatched arrays should have reverted"
        );
    }

    /**
     * @title Batch Burn Requires Approval
     * @notice Batch burning tokens from another account requires operator approval
     * @dev Testing Mode: EXTERNAL
     * @dev Invariant: If !isApprovedForAll(account, operator) and operator != account,
     *      then burnBatch(account, ids, amounts) called by operator must revert
     * @dev This ensures batch burn operations respect the same authorization rules.
     * @custom:property-id ERC1155-EXTERNAL-BURN-055
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155external_batchBurnRequiresApproval(
        uint256 tokenId,
        uint256 amount
    ) public {
        uint256 balance = token.balanceOf(USER1, tokenId);
        require(balance > 0);
        require(msg.sender != USER1);
        require(msg.sender != address(this));
        uint256 burnAmount = amount % (balance + 1);

        // Ensure msg.sender is not approved
        hevm.prank(USER1);
        token.setApprovalForAll(msg.sender, false);
        require(!token.isApprovedForAll(USER1, msg.sender));

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = burnAmount;

        // msg.sender should NOT be able to batch burn USER1's tokens
        hevm.prank(msg.sender);
        this.burnBatch(USER1, ids, amounts);

        assertWithMsg(false, "Batch burn without approval should have reverted");
    }
}
