pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";
import "../../../util/Hevm.sol";

abstract contract CryticERC721ExternalBurnableProperties is CryticERC721ExternalTestBase {
    using Address for address;
    ////////////////////////////////////////
    // Properties

    // The burn function should destroy tokens and reduce the total supply
    function test_ERC721_external_burnReducesTotalSupply() public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 oldTotalSupply = token.totalSupply();

        for(uint256 i; i < selfBalance; i++) {
            uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
            hevm.prank(msg.sender);
            token.burn(tokenId);
        }
        // Check for underflow
        assertWithMsg(selfBalance <= oldTotalSupply, "Underflow - user balance larger than total supply");
        assertEq(oldTotalSupply - selfBalance, token.totalSupply(), "Incorrect supply update on burn");
    }

    // A burned token should not be transferrable
    function test_ERC721_external_burnRevertOnTransfer(address target) public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);
        token.burn(tokenId);
        hevm.prank(msg.sender);
        token.transferFrom(msg.sender, target, tokenId);
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    function test_ERC721_external_burnRevertOnApprove() public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);
        token.burn(tokenId);
        hevm.prank(msg.sender);
        token.approve(address(this), tokenId);
        assertWithMsg(false, "Approving a burned token didn't revert");
    }

    function test_ERC721_external_burnRevertOnGetApproved() public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);
        token.burn(tokenId);
        token.getApproved(tokenId);
        assertWithMsg(false, "getApproved didn't revert for burned token");
    }

    function test_ERC721_external_burnRevertOnOwnerOf() public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, 0);
        hevm.prank(msg.sender);
        token.burn(tokenId);
        token.ownerOf(tokenId);
        assertWithMsg(false, "ownerOf didn't revert for burned token");
    }
}
