pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


abstract contract CryticERC721BurnableProperties is CryticERC721ExternalTestBase, ERC721Burnable {
    using Address for address;

    constructor() {
        isMintableOrBurnable = true;
    }

    ////////////////////////////////////////
    // Properties

    // The burn function should destroy tokens and reduce the total supply
    function test_ERC721_burnReducesTotalSupply(uint256 tokenId) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 oldTotalSupply = totalSupply();
        for(uint256 i; i < selfBalance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            burn(tokenId);
        }

        assertEq(oldTotalSupply - selfBalance, totalSupply(), "Incorrect supply update on burn");
    }

    // A burned token should not be transferrable
    function test_ERC721_burnRevertOnTransfer(address target) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        require(selfBalance > 0);

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        burn(tokenId);
        safeTransferFrom(msg.sender, target, tokenId);
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


    // todo burned token cannot be minted again

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, CryticERC721Base)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, CryticERC721Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
