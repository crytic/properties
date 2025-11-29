// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";
import "../../../util/IHevm.sol";

/**
 * @title ERC721 External Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC721 tokens covering core functionality
 * @dev Testing Mode: EXTERNAL (test harness calls token through external interface)
 * @dev This contract contains 11 properties that test ERC721 core mechanics,
 * @dev including ownership queries, transfers, approvals, and safe transfer callbacks.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC721ExternalBasicProperties {
 * @dev     constructor() {
 * @dev         // Deploy the actual token contract
 * @dev         MyERC721Token tokenContract = new MyERC721Token();
 * @dev         tokenContract.mint(USER1, 1);
 * @dev         tokenContract.mint(USER2, 2);
 * @dev         tokenContract.mint(USER3, 3);
 * @dev
 * @dev         // Initialize the properties contract with token address
 * @dev         initialize(address(tokenContract));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC721ExternalBasicProperties is
    CryticERC721ExternalTestBase
{
    using Address for address;

    /* ================================================================

                        OWNERSHIP PROPERTIES

       Description: Properties verifying ownership queries and constraints
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Balance Query for Zero Address Must Revert
    /// @notice Querying the balance of address(0) should always revert
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `balanceOf(address(0))` must revert
    /// @dev The zero address cannot own tokens according to ERC721 specification.
    /// @dev Implementations must revert when querying the zero address balance to
    /// @dev prevent misuse and maintain standard compliance.
    /// @custom:property-id ERC721-EXTERNAL-OWNERSHIP-051
    function test_ERC721_external_balanceOfZeroAddressMustRevert()
        public
        virtual
    {
        token.balanceOf(address(0));
        assertWithMsg(false, "address(0) balance query should have reverted");
    }

    /// @title Owner Query for Invalid Token Must Revert
    /// @notice Querying the owner of a non-existent token should always revert
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `ownerOf(tokenId)` must revert if `tokenId` does not exist
    /// @dev Non-existent tokens have no owner. Querying ownership of invalid tokens
    /// @dev must revert to prevent confusion and ensure callers can reliably detect
    /// @dev whether a token exists by checking if ownerOf reverts.
    /// @custom:property-id ERC721-EXTERNAL-OWNERSHIP-052
    function test_ERC721_external_ownerOfInvalidTokenMustRevert()
        public
        virtual
    {
        token.ownerOf(type(uint256).max);
        assertWithMsg(false, "Invalid token owner query should have reverted");
    }

    /* ================================================================

                        APPROVAL PROPERTIES

       Description: Properties verifying approval mechanics
       Testing Mode: EXTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Approving Invalid Token Must Revert
    /// @notice Approving a non-existent token should always revert
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `approve(address, tokenId)` must revert if `tokenId` does not exist
    /// @dev Only existing tokens can be approved for transfer. Attempting to approve
    /// @dev a non-existent token must revert to prevent invalid state and ensure
    /// @dev approval logic only operates on valid tokens.
    /// @custom:property-id ERC721-EXTERNAL-APPROVAL-051
    function test_ERC721_external_approvingInvalidTokenMustRevert()
        public
        virtual
    {
        token.approve(address(0), type(uint256).max);
        assertWithMsg(false, "Approving an invalid token should have reverted");
    }

    /* ================================================================

                        TRANSFER PROPERTIES

       Description: Properties verifying transfer mechanics and constraints
       Testing Mode: EXTERNAL
       Property Count: 8

       ================================================================ */

    /// @title TransferFrom Without Approval Must Revert
    /// @notice Transferring a token without approval should revert
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transferFrom(from, to, tokenId)` must revert if caller is not
    /// @dev the owner, not approved for tokenId, and not an operator for owner
    /// @dev The ERC721 standard requires explicit approval before transfers. This
    /// @dev prevents unauthorized token movement and ensures owners maintain control
    /// @dev over their assets unless they explicitly grant transfer rights.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-051
    function test_ERC721_external_transferFromNotApproved(
        address target
    ) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        address approved = token.getApproved(tokenId);
        require(approved != address(this) && !isApproved);

        token.transferFrom(msg.sender, target, tokenId);
        assertWithMsg(false, "transferFrom without approval did not revert");
    }

    /// @title TransferFrom Resets Token Approval
    /// @notice Transferring a token should reset its individual approval
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(from, to, tokenId)`, `getApproved(tokenId)` should be `address(0)`
    /// @dev Token approvals are single-use and specific to the current owner. When
    /// @dev a token is transferred, its approval must be cleared to prevent the previous
    /// @dev approved address from having ongoing rights to the token under new ownership.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-052
    function test_ERC721_external_transferFromResetApproval(
        address target
    ) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        require(target != address(0));

        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        token.approve(address(this), tokenId);
        token.transferFrom(msg.sender, target, tokenId);

        address approved = token.getApproved(tokenId);
        assertWithMsg(approved == address(0), "Approval was not reset");
    }

    /// @title TransferFrom Updates Token Owner
    /// @notice Transferring a token should update its owner correctly
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(from, to, tokenId)`, `ownerOf(tokenId)` should equal `to`
    /// @dev The core purpose of transferFrom is to change token ownership. This property
    /// @dev verifies that ownership is properly updated after a transfer, ensuring the
    /// @dev recipient becomes the new owner and ownership queries reflect this change.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-053
    function test_ERC721_external_transferFromUpdatesOwner(
        address target
    ) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        require(target != address(0));
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try token.transferFrom(msg.sender, target, tokenId) {
            assertWithMsg(
                token.ownerOf(tokenId) == target,
                "Token owner not updated"
            );
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    /// @title TransferFrom Zero Address Must Revert
    /// @notice Transferring from the zero address should always revert
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transferFrom(address(0), to, tokenId)` must revert
    /// @dev The zero address cannot own tokens, so it cannot be the source of a transfer.
    /// @dev Implementations must reject transfers from the zero address to maintain
    /// @dev consistency with the ownership model and prevent invalid state.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-054
    function test_ERC721_external_transferFromZeroAddress(
        address target,
        uint256 tokenId
    ) public virtual {
        token.transferFrom(address(0), target, tokenId);

        assertWithMsg(
            false,
            "transferFrom does not revert when `from` is the zero-address"
        );
    }

    /// @title Transfer To Zero Address Must Revert
    /// @notice Transferring to the zero address should always revert
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `transferFrom(from, address(0), tokenId)` must revert
    /// @dev Transfers to the zero address are equivalent to burning, which requires
    /// @dev explicit burn functions. Regular transfers must reject the zero address
    /// @dev as destination to prevent accidental token loss.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-055
    function test_ERC721_external_transferToZeroAddress() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        token.transferFrom(msg.sender, address(0), tokenId);

        assertWithMsg(false, "Transfer to zero address should have reverted");
    }

    /// @title Self Transfer Should Not Break Accounting
    /// @notice Transferring a token to oneself should maintain correct state
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(owner, owner, tokenId)`, owner and balance remain unchanged
    /// @dev Self-transfers are a valid edge case that must not corrupt state. The owner
    /// @dev should remain unchanged and the balance should remain constant, as no actual
    /// @dev transfer of ownership occurs.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-056
    function test_ERC721_external_transferFromSelf() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);

        try token.transferFrom(msg.sender, msg.sender, tokenId) {
            assertWithMsg(
                token.ownerOf(tokenId) == msg.sender,
                "Self transfer changes owner"
            );
            assertEq(
                token.balanceOf(msg.sender),
                selfBalance,
                "Self transfer breaks accounting"
            );
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    /// @title Self Transfer Resets Approval
    /// @notice Self-transferring a token should reset its approval
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `transferFrom(owner, owner, tokenId)`, `getApproved(tokenId)` should be `address(0)`
    /// @dev Even in self-transfers, token approvals must be cleared to maintain consistency
    /// @dev with standard transfer behavior. This prevents stale approvals from persisting
    /// @dev and ensures uniform approval semantics across all transfer scenarios.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-057
    function test_ERC721_external_transferFromSelfResetsApproval()
        public
        virtual
    {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        require(token.ownerOf(tokenId) == msg.sender);

        hevm.prank(msg.sender);
        token.approve(address(this), tokenId);

        token.transferFrom(msg.sender, msg.sender, tokenId);
        assertWithMsg(
            token.getApproved(tokenId) == address(0),
            "Self transfer does not reset approvals"
        );
    }

    /// @title SafeTransferFrom Must Check Receiver Implementation
    /// @notice SafeTransferFrom should revert if receiver doesn't implement ERC721Receiver
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: `safeTransferFrom(from, to, tokenId)` must revert if `to` is a contract
    /// @dev that doesn't implement `onERC721Received()`
    /// @dev The safe transfer functions exist to prevent tokens from being locked in
    /// @dev contracts that cannot handle them. Implementations must verify that contract
    /// @dev receivers implement the proper callback to accept ERC721 tokens.
    /// @custom:property-id ERC721-EXTERNAL-TRANSFER-058
    function test_ERC721_external_safeTransferFromRevertsOnNoncontractReceiver()
        public
        virtual
    {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);

        token.safeTransferFrom(
            msg.sender,
            address(mockUnsafeReceiver),
            tokenId
        );
        assertWithMsg(
            false,
            "safeTransferFrom does not revert if receiver does not implement ERC721.onERC721Received"
        );
    }
}
