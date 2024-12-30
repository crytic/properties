// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


abstract contract CryticERC721BurnableProperties is CryticERC721TestBase, ERC721Burnable {
    using Address for address;

    ////////////////////////////////////////
    // Properties

    // The burn function should destroy tokens and reduce the total supply
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

    // A burned token should not be transferrable
    function test_ERC721_burnRevertOnTransferFromPreviousOwner(address target) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        transferFrom(msg.sender, target, tokenId);
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    function test_ERC721_burnRevertOnTransferFromZeroAddress(address target) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        transferFrom(address(0), target, tokenId);
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    function test_ERC721_burnRevertOnApprove() public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        approve(address(this), tokenId);
        assertWithMsg(false, "Approving a burned token didn't revert");
    }

    function test_ERC721_burnRevertOnGetApproved() public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        getApproved(tokenId);
        assertWithMsg(false, "getApproved didn't revert for burned token");
    }

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
