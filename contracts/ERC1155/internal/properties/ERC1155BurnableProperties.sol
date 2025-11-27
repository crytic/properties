// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC1155TestBase.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/**
 * @title ERC1155 Burnable Properties
 * @author Crytic (Trail of Bits)
 * @notice Invariant properties for ERC1155 tokens with burn functionality
 * @dev Testing Mode: INTERNAL
 * @dev This contract contains properties that must hold for ERC1155 implementations
 * with burn functionality. These properties ensure that burning tokens correctly
 * reduces balances and that only authorized parties can burn tokens.
 *
 * Properties are organized into the following sections:
 * - Burn Properties: Tests for single token burn operations
 * - Batch Burn Properties: Tests for batch burn operations
 *
 * @custom:see https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract CryticERC1155BurnableProperties is
    CryticERC1155TestBase,
    ERC1155Burnable
{
    constructor(string memory uri) CryticERC1155TestBase(uri) {
        isMintableOrBurnable = true;
    }

    ////////////////////////////////////////////////////////////////
    //                     Burn Properties                        //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Burn Reduces Balance
     * @notice Burning tokens must reduce the owner's balance by the burn amount
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: After burn(account, id, amount), balanceOf(account, id) decreases by amount
     * @dev Burn operations must correctly update token balances to maintain accurate accounting.
     * @custom:property-id ERC1155-BURN-001
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155_burnReducesBalance(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        uint256 burnAmount = amount % (balance + 1);

        this.burn(address(this), tokenId, burnAmount);

        assertEq(
            balanceOf(address(this), tokenId),
            balance - burnAmount,
            "Balance not reduced correctly after burn"
        );
    }

    /**
     * @title Burn from Another Account Requires Approval
     * @notice Burning tokens from another account requires operator approval
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: If !isApprovedForAll(account, operator) and operator != account,
     *      then burn(account, id, amount) called by operator must revert
     * @dev This prevents unauthorized token destruction.
     * @custom:property-id ERC1155-BURN-002
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155_burnRequiresApproval(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(USER1, tokenId);
        require(balance > 0);
        require(msg.sender != USER1);
        require(msg.sender != address(this));
        uint256 burnAmount = amount % (balance + 1);

        // Ensure msg.sender is not approved
        hevm.prank(USER1);
        IERC1155(address(this)).setApprovalForAll(msg.sender, false);
        require(!isApprovedForAll(USER1, msg.sender));

        // msg.sender should NOT be able to burn USER1's tokens
        hevm.prank(msg.sender);
        ERC1155Burnable(address(this)).burn(USER1, tokenId, burnAmount);

        assertWithMsg(false, "Burn without approval should have reverted");
    }

    /**
     * @title Approved Operator Can Burn
     * @notice Approved operators must be able to burn owner's tokens
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: If isApprovedForAll(account, operator), then operator can
     *      call burn(account, id, amount)
     * @dev This ensures operator approval extends to burn operations.
     * @custom:property-id ERC1155-BURN-003
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155_approvedOperatorCanBurn(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(address(this), tokenId);
        require(balance > 0);
        require(msg.sender != address(this));
        uint256 burnAmount = amount % (balance + 1);

        // Approve msg.sender as operator
        this.setApprovalForAll(msg.sender, true);
        require(isApprovedForAll(address(this), msg.sender));

        // msg.sender should be able to burn tokens from address(this)
        hevm.prank(msg.sender);
        try ERC1155Burnable(address(this)).burn(address(this), tokenId, burnAmount) {
            assertEq(
                balanceOf(address(this), tokenId),
                balance - burnAmount,
                "Balance not updated after operator burn"
            );
        } catch {
            assertWithMsg(false, "Operator burn unexpectedly reverted");
        }
    }

    ////////////////////////////////////////////////////////////////
    //                 Batch Burn Properties                      //
    ////////////////////////////////////////////////////////////////

    /**
     * @title Batch Burn Reduces All Balances
     * @notice Burning multiple tokens in a batch must reduce all balances correctly
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: After burnBatch(account, ids, amounts), all corresponding
     *      balances decrease by the specified amounts
     * @dev Batch operations must maintain the same correctness as individual operations.
     * @custom:property-id ERC1155-BURN-004
     *
     * @param tokenId1 First token ID to burn
     * @param tokenId2 Second token ID to burn
     * @param amount1 Amount of first token to burn
     * @param amount2 Amount of second token to burn
     */
    function test_ERC1155_batchBurnReducesBalances(
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 amount1,
        uint256 amount2
    ) public {
        uint256 balance1 = balanceOf(address(this), tokenId1);
        uint256 balance2 = balanceOf(address(this), tokenId2);
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
            balanceOf(address(this), tokenId1),
            balance1 - burnAmount1,
            "Balance 1 not reduced correctly after batch burn"
        );
        assertEq(
            balanceOf(address(this), tokenId2),
            balance2 - burnAmount2,
            "Balance 2 not reduced correctly after batch burn"
        );
    }

    /**
     * @title Batch Burn Array Length Mismatch Should Revert
     * @notice Batch burn with mismatched array lengths must revert
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: burnBatch must revert if ids.length != amounts.length
     * @dev This prevents ambiguous batch operations and programming errors.
     * @custom:property-id ERC1155-BURN-005
     */
    function test_ERC1155_batchBurnArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10;

        this.burnBatch(address(this), ids, amounts);
        assertWithMsg(false, "Batch burn with mismatched arrays should have reverted");
    }

    /**
     * @title Batch Burn Requires Approval
     * @notice Batch burning tokens from another account requires operator approval
     * @dev Testing Mode: INTERNAL
     * @dev Invariant: If !isApprovedForAll(account, operator) and operator != account,
     *      then burnBatch(account, ids, amounts) called by operator must revert
     * @dev This ensures batch burn operations respect the same authorization rules.
     * @custom:property-id ERC1155-BURN-006
     *
     * @param tokenId The token ID to burn
     * @param amount The amount to burn
     */
    function test_ERC1155_batchBurnRequiresApproval(uint256 tokenId, uint256 amount) public {
        uint256 balance = balanceOf(USER1, tokenId);
        require(balance > 0);
        require(msg.sender != USER1);
        require(msg.sender != address(this));
        uint256 burnAmount = amount % (balance + 1);

        // Ensure msg.sender is not approved
        hevm.prank(USER1);
        IERC1155(address(this)).setApprovalForAll(msg.sender, false);
        require(!isApprovedForAll(USER1, msg.sender));

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = burnAmount;

        // msg.sender should NOT be able to batch burn USER1's tokens
        hevm.prank(msg.sender);
        ERC1155Burnable(address(this)).burnBatch(USER1, ids, amounts);

        assertWithMsg(false, "Batch burn without approval should have reverted");
    }
}
