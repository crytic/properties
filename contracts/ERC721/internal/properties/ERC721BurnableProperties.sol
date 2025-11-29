// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/**
 * @title ERC721 Burnable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC721 tokens with burn functionality
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 6 properties that test token burning mechanics,
 * @dev including burn(), supply updates, and post-burn state validation.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyBurnableERC721Token, CryticERC721BurnableProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, 1);
 * @dev         _mint(USER2, 2);
 * @dev         _mint(USER3, 3);
 * @dev         isMintableOrBurnable = true; // Must be true for burnable tokens
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC721BurnableProperties is CryticERC721TestBase, ERC721Burnable {
    using Address for address;

    constructor() {
        isMintableOrBurnable = true;
    }

    /* ================================================================

                        BURN PROPERTIES

       Description: Properties verifying token burning mechanics
       Testing Mode: INTERNAL
       Property Count: 6

       ================================================================ */

    /// @title Burn Reduces Total Supply
    /// @notice Burning tokens should decrease the total supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(tokenId)`, `totalSupply()` decreases by 1
    /// @dev Burned tokens must be permanently removed from circulation. The total
    /// @dev supply must accurately reflect the number of existing tokens by decreasing
    /// @dev when tokens are burned, ensuring correct supply accounting.
    /// @custom:property-id ERC721-BURN-001
    function test_ERC721_burnReducesTotalSupply() public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 oldTotalSupply = totalSupply();
        for(uint256 i; i < selfBalance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            burn(tokenId);
        }

        assertWithMsg(selfBalance <= oldTotalSupply, "Underflow - user balance larger than total supply");
        assertEq(oldTotalSupply - selfBalance, totalSupply(), "Incorrect supply update on burn");
    }

    /// @title Burned Token Cannot Be Transferred From Previous Owner
    /// @notice Burned tokens should not be transferable from their previous owner
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(tokenId)`, `transferFrom(previousOwner, to, tokenId)` must revert
    /// @dev Once a token is burned, it ceases to exist and cannot be transferred.
    /// @dev Attempting to transfer a burned token from its previous owner must revert
    /// @dev to prevent invalid operations on non-existent tokens.
    /// @custom:property-id ERC721-BURN-002
    function test_ERC721_burnRevertOnTransferFromPreviousOwner(address target) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        transferFrom(msg.sender, target, tokenId);
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    /// @title Burned Token Cannot Be Transferred From Zero Address
    /// @notice Burned tokens should not be transferable from zero address
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(tokenId)`, `transferFrom(address(0), to, tokenId)` must revert
    /// @dev Burned tokens are permanently destroyed and cannot be transferred from any address,
    /// @dev including the zero address. This ensures burned tokens cannot be resurrected
    /// @dev through invalid transfer operations.
    /// @custom:property-id ERC721-BURN-003
    function test_ERC721_burnRevertOnTransferFromZeroAddress(address target) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        transferFrom(address(0), target, tokenId);
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    /// @title Burned Token Cannot Be Approved
    /// @notice Approving a burned token should revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(tokenId)`, `approve(to, tokenId)` must revert
    /// @dev Non-existent tokens cannot be approved for transfer. Attempting to
    /// @dev approve a burned token must revert because approvals only make sense
    /// @dev for tokens that exist and can be transferred.
    /// @custom:property-id ERC721-BURN-004
    function test_ERC721_burnRevertOnApprove() public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        approve(address(this), tokenId);
        assertWithMsg(false, "Approving a burned token didn't revert");
    }

    /// @title GetApproved Must Revert For Burned Token
    /// @notice Querying approval for a burned token should revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(tokenId)`, `getApproved(tokenId)` must revert
    /// @dev Burned tokens have no approval state because they no longer exist.
    /// @dev Querying approvals for non-existent tokens must revert to clearly
    /// @dev indicate the token is invalid rather than returning misleading data.
    /// @custom:property-id ERC721-BURN-005
    function test_ERC721_burnRevertOnGetApproved() public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        getApproved(tokenId);
        assertWithMsg(false, "getApproved didn't revert for burned token");
    }

    /// @title OwnerOf Must Revert For Burned Token
    /// @notice Querying owner of a burned token should revert
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(tokenId)`, `ownerOf(tokenId)` must revert
    /// @dev Burned tokens have no owner because they cease to exist. The ownerOf
    /// @dev function must revert for burned tokens to clearly indicate the token
    /// @dev is no longer valid, consistent with behavior for never-minted tokens.
    /// @custom:property-id ERC721-BURN-006
    function test_ERC721_burnRevertOnOwnerOf() public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        ownerOf(tokenId);
        assertWithMsg(false, "ownerOf didn't revert for burned token");
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, CryticERC721TestBase)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, CryticERC721TestBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
