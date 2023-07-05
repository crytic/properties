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
        _approve(address(0), tokenId);
        _setApprovalForAll(target, msg.sender, false);
        require(ownerOf(tokenId) == target);

        transferFrom(target, msg.sender, tokenId);
        assertWithMsg(false, "using transferFrom without being approved should have reverted");
    }

    // transferFrom should reset approval for that token
    function test_ERC721_transferFromResetApproval(address target) public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);  
        require(target != address(this));
        require(target != msg.sender);
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        hevm.prank(msg.sender);
        try IERC721(address(this)).transferFrom(msg.sender, target, tokenId) {
            address approved = getApproved(tokenId);
            assertWithMsg(approved == address(0), "Approval was not reset");
        } catch {
            assertWithMsg(false, "transferFrom unexpectedly reverted");
        }
    }

    // transferFrom correctly updates owner
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

    function test_ERC721_transferFromZeroAddress(address target, uint256 tokenId) public virtual {
        require(target != address(this));
        require(target != msg.sender);
        transferFrom(address(0), target, tokenId);

        assertWithMsg(false, "Transfer from zero address did not revert");
    }

    // Transfers to the zero address should revert
    function test_ERC721_transferToZeroAddress() public virtual {
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0); 
        uint tokenId = tokenOfOwnerByIndex(msg.sender, 0);

        transferFrom(msg.sender, address(0), tokenId);

        assertWithMsg(false, "Transfer to zero address should have reverted");
    }

    // Transfers to self should not break accounting
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

    // Transfer to self reset approval
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

    // safeTransferFrom reverts if receiver does not implement the callback
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
