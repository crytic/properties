// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ERC721 Basic Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC721 tokens covering core functionality
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 11 properties that test ERC721 core mechanics,
 * @dev including ownership queries, transfers, approvals, and safe transfer callbacks.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC721Token, CryticERC721BasicProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, 1);
 * @dev         _mint(USER2, 2);
 * @dev         _mint(USER3, 3);
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC721BasicProperties is CryticERC721TestBase {
    using Address for address;

    /* ================================================================

                        OWNERSHIP PROPERTIES

       Description: Properties verifying ownership queries and constraints
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Balance Query for Zero Address Must Revert
    /// @notice Querying the balance of address(0) should always revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `balanceOf(address(0))` must revert
    /// @dev The zero address cannot own tokens according to ERC721 specification.
    /// @dev Implementations must revert when querying the zero address balance to
    /// @dev prevent misuse and maintain standard compliance.
    /// @custom:property-id ERC721-OWNERSHIP-001
    function test_ERC721_balanceOfZeroAddressMustRevert() public virtual {
        balanceOf(address(0));
        assertWithMsg(false, "address(0) balance query should have reverted");
    }

    /// @title Owner Query for Invalid Token Must Revert
    /// @notice Querying the owner of a non-existent token should always revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `ownerOf(tokenId)` must revert if `tokenId` does not exist
    /// @dev Non-existent tokens have no owner. Querying ownership of invalid tokens
    /// @dev must revert to prevent confusion and ensure callers can reliably detect
    /// @dev whether a token exists by checking if ownerOf reverts.
    /// @custom:property-id ERC721-OWNERSHIP-002
    function test_ERC721_ownerOfInvalidTokenMustRevert(uint256 tokenId) public virtual {
        require(!_exists(tokenId));
        ownerOf(tokenId);
        assertWithMsg(false, "Invalid token owner query should have reverted");
    }

    /* ================================================================

                        APPROVAL PROPERTIES

       Description: Properties verifying approval mechanics
       Testing Mode: INTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Approving Invalid Token Must Revert
    /// @notice Approving a non-existent token should always revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `approve(address, tokenId)` must revert if `tokenId` does not exist
    /// @dev Only existing tokens can be approved for transfer. Attempting to approve
    /// @dev a non-existent token must revert to prevent invalid state and ensure
    /// @dev approval logic only operates on valid tokens.
    /// @custom:property-id ERC721-APPROVAL-001
    function test_ERC721_approvingInvalidTokenMustRevert(uint256 tokenId) public virtual {
        require(!_exists(tokenId));
        approve(address(0), tokenId);
        assertWithMsg(false, "Approving an invalid token should have reverted");
    }

    /* ================================================================

                        TRANSFER PROPERTIES

       Description: Properties verifying transfer mechanics and constraints
       Testing Mode: INTERNAL
       Property Count: 8

       ================================================================ */

    /// @title TransferFrom Without Approval Must Revert
    /// @notice Transferring a token without approval should revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transferFrom(from, to, tokenId)` must revert if caller is not
    /// @dev the owner, not approved for tokenId, and not an operator for owner
    /// @dev The ERC721 standard requires explicit approval before transfers. This
    /// @dev prevents unauthorized token movement and ensures owners maintain control
    /// @dev over their assets unless they explicitly grant transfer rights.
    /// @custom:property-id ERC721-TRANSFER-001
    function test_ERC721_transferFromNotApproved(address target) public virtual {
        uint256 selfBalance = balanceOf(target);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(target, 0);
        _approve(address(0), tokenId);
        _setApprovalForAll(target, msg.sender, false);
        require(ownerOf(tokenId) == target);

        transferFrom(target, msg.sender, tokenId);
        assertWithMsg(false, "using transferFrom without being approved should have reverted");
    }

    /// @title TransferFrom Resets Token Approval
    /// @notice Transferring a token should reset its individual approval
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(from, to, tokenId)`, `getApproved(tokenId)` should be `address(0)`
    /// @dev Token approvals are single-use and specific to the current owner. When
    /// @dev a token is transferred, its approval must be cleared to prevent the previous
    /// @dev approved address from having ongoing rights to the token under new ownership.
    /// @custom:property-id ERC721-TRANSFER-002
    function test_ERC721_transferFromResetApproval(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        require(target != address(0));
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try IERC721(address(this)).transferFrom(msg.sender, target, tokenId) {
            address approved = getApproved(tokenId);
            assertWithMsg(approved == address(0), "Approval was not reset");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    /// @title TransferFrom Updates Token Owner
    /// @notice Transferring a token should update its owner correctly
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(from, to, tokenId)`, `ownerOf(tokenId)` should equal `to`
    /// @dev The core purpose of transferFrom is to change token ownership. This property
    /// @dev verifies that ownership is properly updated after a transfer, ensuring the
    /// @dev recipient becomes the new owner and ownership queries reflect this change.
    /// @custom:property-id ERC721-TRANSFER-003
    function test_ERC721_transferFromUpdatesOwner(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        require(target != address(0));
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try IERC721(address(this)).transferFrom(msg.sender, target, tokenId) {
            assertWithMsg(ownerOf(tokenId) == target, "Token owner not updated");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    /// @title TransferFrom Zero Address Must Revert
    /// @notice Transferring from the zero address should always revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transferFrom(address(0), to, tokenId)` must revert
    /// @dev The zero address cannot own tokens, so it cannot be the source of a transfer.
    /// @dev Implementations must reject transfers from the zero address to maintain
    /// @dev consistency with the ownership model and prevent invalid state.
    /// @custom:property-id ERC721-TRANSFER-004
    function test_ERC721_transferFromZeroAddress(address target, uint256 tokenId) public virtual {
        require(target != address(this));
        require(target != msg.sender);
        transferFrom(address(0), target, tokenId);

        assertWithMsg(false, "Transfer from zero address did not revert");
    }

    /// @title Transfer To Zero Address Must Revert
    /// @notice Transferring to the zero address should always revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `transferFrom(from, address(0), tokenId)` must revert
    /// @dev Transfers to the zero address are equivalent to burning, which requires
    /// @dev explicit burn functions. Regular transfers must reject the zero address
    /// @dev as destination to prevent accidental token loss.
    /// @custom:property-id ERC721-TRANSFER-005
    function test_ERC721_transferToZeroAddress() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        transferFrom(msg.sender, address(0), tokenId);

        assertWithMsg(false, "Transfer to zero address should have reverted");
    }

    /// @title Self Transfer Should Not Break Accounting
    /// @notice Transferring a token to oneself should maintain correct state
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(owner, owner, tokenId)`, owner and balance remain unchanged
    /// @dev Self-transfers are a valid edge case that must not corrupt state. The owner
    /// @dev should remain unchanged and the balance should remain constant, as no actual
    /// @dev transfer of ownership occurs.
    /// @custom:property-id ERC721-TRANSFER-006
    function test_ERC721_transferFromSelf() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try IERC721(address(this)).transferFrom(msg.sender, msg.sender, tokenId) {
            assertWithMsg(ownerOf(tokenId) == msg.sender, "Self transfer changes owner");
            assertEq(balanceOf(msg.sender), selfBalance, "Self transfer breaks accounting");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    /// @title Self Transfer Resets Approval
    /// @notice Self-transferring a token should reset its approval
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `transferFrom(owner, owner, tokenId)`, `getApproved(tokenId)` should be `address(0)`
    /// @dev Even in self-transfers, token approvals must be cleared to maintain consistency
    /// @dev with standard transfer behavior. This prevents stale approvals from persisting
    /// @dev and ensures uniform approval semantics across all transfer scenarios.
    /// @custom:property-id ERC721-TRANSFER-007
    function test_ERC721_transferFromSelfResetsApproval() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try IERC721(address(this)).transferFrom(msg.sender, msg.sender, tokenId) {
            assertWithMsg(getApproved(tokenId) == address(0), "Self transfer does not reset approvals");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    /// @title SafeTransferFrom Must Check Receiver Implementation
    /// @notice SafeTransferFrom should revert if receiver doesn't implement ERC721Receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `safeTransferFrom(from, to, tokenId)` must revert if `to` is a contract
    /// @dev that doesn't implement `onERC721Received()`
    /// @dev The safe transfer functions exist to prevent tokens from being locked in
    /// @dev contracts that cannot handle them. Implementations must verify that contract
    /// @dev receivers implement the proper callback to accept ERC721 tokens.
    /// @custom:property-id ERC721-TRANSFER-008
    function test_ERC721_safeTransferFromRevertsOnNoncontractReceiver(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        require(ownerOf(tokenId) == msg.sender);

        safeTransferFrom(msg.sender, address(unsafeReceiver), tokenId);
        assertWithMsg(false, "safeTransferFrom does not revert if receiver does not implement ERC721.onERC721Received");
    }
}
