pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract CryticERC721BasicProperties is CryticERC721TestBase {
    using Address for address;

    ////////////////////////////////////////
    // Properties

    // Querying the balance of address(0) should throw
    function test_ERC20_balanceOfZeroAddressMustRevert() public virtual {
        balanceOf(address(0));
        assertWithMsg(false, "address(0) balance query should have reverted");
    }

    // Querying the owner of an invalid token should throw
    function test_ERC721_ownerOfInvalidTokenMustRevert(uint256 tokenId) public virtual {
        require(!_exists(tokenId));
        ownerOf(tokenId);
        assertWithMsg(false, "Invalid token owner query should have reverted");
    }

    // Approving an invalid token should throw
    function test_ERC721_approvingInvalidTokenMustRevert(uint256 tokenId) public virtual {
        require(!_exists(tokenId));
        approve(address(0), tokenId);
        assertWithMsg(false, "Approving an invalid token should have reverted");
    }

    // transferFrom a token that the caller is not approved for should revert
    function test_ERC721_transferFromNotApproved(address target) public virtual {
        uint256 selfBalance = balanceOf(target);
        require(selfBalance > 0);        
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(target, 0);
        bool isApproved = isApprovedForAll(target, address(this));
        address approved = getApproved(tokenId);
        require(approved != address(this) && !isApproved);
        require(ownerOf(tokenId) == target);

        transferFrom(target, msg.sender, tokenId);
        assertWithMsg(ownerOf(tokenId) == target, "Target");
        assertWithMsg(ownerOf(tokenId) == msg.sender, "Transferred a token without being approved.");
        
    }

    // transferFrom should reset approval for that token
    function test_ERC721_transferFromResetApproval(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);  
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = isApprovedForAll(msg.sender, address(this));
        address approved = getApproved(tokenId);
        require(approved == address(this) || isApproved);
        transferFrom(msg.sender, target, tokenId);

        approved = getApproved(tokenId);
        assertWithMsg(approved == address(0), "Approval was not reset");
    }

    // transferFrom correctly updates owner
    function test_ERC721_transferFromUpdatesOwner(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);  
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = isApprovedForAll(msg.sender, address(this));
        address approved = getApproved(tokenId);
        require(approved == address(this) || isApproved);
        transferFrom(msg.sender, target, tokenId);

        assertWithMsg(ownerOf(tokenId) == target, "Token owner not updated");
    }

    function test_ERC721_transferFromZeroAddress(address target, uint256 tokenId) public virtual {
        require(target != address(this));
        require(target != msg.sender);
        transferFrom(address(0), target, tokenId);

        assertWithMsg(ownerOf(tokenId) != target, "Transfered from zero address");
    }

    // Transfers to the zero address should revert
    function test_ERC721_transferToZeroAddress() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        transferFrom(msg.sender, address(0), tokenId);

        assertWithMsg(ownerOf(tokenId) == address(0), "Transfer to zero address should have reverted");
    }

    // Transfers to self should not break accounting
    function test_ERC721_transferFromSelf() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = isApprovedForAll(msg.sender, address(this));
        address approved = getApproved(tokenId);
        require(approved == address(this) || isApproved);

        transferFrom(msg.sender, msg.sender, tokenId);
        assertWithMsg(ownerOf(tokenId) == msg.sender, "Self transfer changes owner");
        assertEq(balanceOf(msg.sender), selfBalance, "Self transfer breaks accounting");
    }

    // Transfer to self reset approval
    function test_ERC721_transferFromSelfResetsApproval() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = isApprovedForAll(msg.sender, address(this));
        address approved = getApproved(tokenId);
        require(approved == address(this) || isApproved);

        transferFrom(msg.sender, msg.sender, tokenId);
        assertWithMsg(getApproved(tokenId) == address(0), "Self transfer does not reset approvals");
    }

    // safeTransferFrom reverts if receiver does not implement the callback
    function test_ERC721_safeTransferFromRevertsOnNoncontractReceiver(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0); 
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        bool isApproved = isApprovedForAll(msg.sender, address(this));
        address approved = getApproved(tokenId);
        require(approved == address(this) || isApproved);
        require(ownerOf(tokenId) == msg.sender);
        
        safeTransferFrom(msg.sender, address(unsafeReceiver), tokenId);
        assertWithMsg(ownerOf(tokenId) == msg.sender, "safeTransferFrom does not revert if receiver does not implement ERC721.onERC721Received");
    }

    // todo test_ERC721_setApprovalForAllWorksAsExpected
    // todo safeTransferFrom checks

}
