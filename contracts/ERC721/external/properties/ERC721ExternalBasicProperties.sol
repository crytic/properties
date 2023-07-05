pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";
import "../../../util/Hevm.sol";

abstract contract CryticERC721ExternalBasicProperties is CryticERC721ExternalTestBase {
    using Address for address;

    ////////////////////////////////////////
    // Properties

    // Querying the balance of address(0) should throw
    function test_ERC721_external_balanceOfZeroAddressMustRevert() public virtual {
        token.balanceOf(address(0));
        assertWithMsg(false, "address(0) balance query should have reverted");
    }

    // Querying the owner of an invalid token should throw
    function test_ERC721_external_ownerOfInvalidTokenMustRevert() public virtual {
        token.ownerOf(type(uint256).max);
        assertWithMsg(false, "Invalid token owner query should have reverted");
    }

    // Approving an invalid token should throw
    function test_ERC721_external_approvingInvalidTokenMustRevert() public virtual {
        token.approve(address(0), type(uint256).max);
        assertWithMsg(false, "Approving an invalid token should have reverted");
    }

    // transferFrom a token that the caller is not approved for should revert
    function test_ERC721_external_transferFromNotApproved(address target) public virtual {
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

    // transferFrom should reset approval for that token
    function test_ERC721_external_transferFromResetApproval(address target) public virtual {
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

    // transferFrom correctly updates owner
    function test_ERC721_external_transferFromUpdatesOwner(address target) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);  
        require(target != address(this));
        require(target != msg.sender);
        require(target != address(0));
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try token.transferFrom(msg.sender, target, tokenId) {
            assertWithMsg(token.ownerOf(tokenId) == target, "Token owner not updated");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    // transfer from zero address should revert
    function test_ERC721_external_transferFromZeroAddress(address target, uint256 tokenId) public virtual {
        token.transferFrom(address(0), target, tokenId);

        assertWithMsg(false, "transferFrom does not revert when `from` is the zero-address");
    }

    // Transfers to the zero address should revert
    function test_ERC721_external_transferToZeroAddress() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        token.transferFrom(msg.sender, address(0), tokenId);

        assertWithMsg(false, "Transfer to zero address should have reverted");
    }

    // Transfers to self should not break accounting
    function test_ERC721_external_transferFromSelf() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);

        try token.transferFrom(msg.sender, msg.sender, tokenId) {
            assertWithMsg(token.ownerOf(tokenId) == msg.sender, "Self transfer changes owner");
            assertEq(token.balanceOf(msg.sender), selfBalance, "Self transfer breaks accounting");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }

    }

    // Transfer to self reset approval
    function test_ERC721_external_transferFromSelfResetsApproval() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        require(token.ownerOf(tokenId) == msg.sender);

        hevm.prank(msg.sender);
        token.approve(address(this), tokenId);

        token.transferFrom(msg.sender, msg.sender, tokenId);
        assertWithMsg(token.getApproved(tokenId) == address(0), "Self transfer does not reset approvals");
    }

    // safeTransferFrom reverts if receiver does not implement the callback
    function test_ERC721_external_safeTransferFromRevertsOnNoncontractReceiver() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);

        token.safeTransferFrom(msg.sender, address(mockUnsafeReceiver), tokenId);
        assertWithMsg(false, "safeTransferFrom does not revert if receiver does not implement ERC721.onERC721Received");
    }

}
