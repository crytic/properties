pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";

abstract contract CryticERC721ExternalBasicProperties is CryticERC721ExternalTestBase {
    using Address for address;

    constructor() {
    }

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
        assertWithMsg(false, "Breakpoint");
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
        assertWithMsg(token.ownerOf(tokenId) == msg.sender, "Transferred a token without being approved.");
    }

    // transferFrom should reset approval for that token
    function test_ERC721_external_transferFromResetApproval(address target) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);  
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        address approved = token.getApproved(tokenId);
        require(approved == address(this) || isApproved);
        token.transferFrom(msg.sender, target, tokenId);

        approved = token.getApproved(tokenId);
        assertWithMsg(approved == address(0), "Approval was not reset");
    }

    // transferFrom correctly updates owner
    function test_ERC721_external_transferFromUpdatesOwner(address target) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);  
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        address approved = token.getApproved(tokenId);
        require(approved == address(this) || isApproved);
        token.transferFrom(msg.sender, target, tokenId);

        assertWithMsg(token.ownerOf(tokenId) == target, "Token owner not updated");
    }

    // transfer from zero address should revert
    function test_ERC721_external_transferFromZeroAddress(address target, uint256 tokenId) public virtual {
        require(target != address(this));
        require(target != msg.sender);
        token.transferFrom(address(0), target, tokenId);

        assertWithMsg(token.ownerOf(tokenId) != target, "Transfered from zero address");
    }

    // Transfers to the zero address should revert
    function test_ERC721_external_transferToZeroAddress() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);

        token.transferFrom(msg.sender, address(0), tokenId);

        assertWithMsg(token.ownerOf(tokenId) == address(0), "Transfer to zero address should have reverted");
    }

    // Transfers to self should not break accounting
    function test_ERC721_external_transferFromSelf() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        address approved = token.getApproved(tokenId);
        require(approved == address(this) || isApproved);

        token.transferFrom(msg.sender, msg.sender, tokenId);
        assertWithMsg(token.ownerOf(tokenId) == msg.sender, "Self transfer changes owner");
        assertEq(token.balanceOf(msg.sender), selfBalance, "Self transfer breaks accounting");
    }

    // Transfer to self reset approval
    function test_ERC721_external_transferFromSelfResetsApproval() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        address approved = token.getApproved(tokenId);
        require(approved == address(this) || isApproved);

        token.transferFrom(msg.sender, msg.sender, tokenId);
        assertWithMsg(token.getApproved(tokenId) == address(0), "Self transfer does not reset approvals");
    }

    // safeTransferFrom reverts if receiver does not implement the callback
    function test_ERC721_external_safeTransferFromRevertsOnNoncontractReceiver() public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = token.isApprovedForAll(msg.sender, address(this));
        address approved = token.getApproved(tokenId);
        require(approved == address(this) || isApproved);

        token.safeTransferFrom(msg.sender, address(mockUnsafeReceiver), tokenId);
        assertWithMsg(false, "safeTransferFrom does not revert if receiver does not implement ERC721.onERC721Received");
    }

    // todo test_ERC721_external_setApprovalForAllWorksAsExpected
    // todo safeTransferFrom checks

}
