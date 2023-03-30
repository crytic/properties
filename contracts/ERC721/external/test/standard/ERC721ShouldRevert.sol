pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {CryticERC721ExternalPropertyTests} from "../../ERC721ExternalPropertyTests.sol";
import {IERC721Internal} from "../../../util/IERC721Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC721ShouldRevert is ERC721, ERC721Enumerable {
    using Address for address;
    
    uint256 public counter;
    uint256 public maxSupply;
    bool public isMintableOrBurnable;

    constructor() ERC721("OZERC721","OZ") {
        maxSupply = 100;
        isMintableOrBurnable = true;
    }

    function balanceOf(address owner) public view virtual override(ERC721, IERC721) returns (uint256) {
        //require(owner != address(0), "ERC721: address zero is not a valid owner");
        return owner == address(0) ? 0 : super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        address owner = _ownerOf(tokenId);
        //require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if(_exists(tokenId)) {
            super.approve(to, tokenId);
        }

        // Does not revert if token doesn't exist
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        //require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        if (from == address(0)) {
            _mint(to, tokenId);
        } else if (getApproved(tokenId) != msg.sender && !isApprovedForAll(from, msg.sender) || to == address(0)) {
            _burn(tokenId);
            _mint(to, tokenId);
        } else {
            ERC721._transfer(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, "") returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    _transfer(from, to, tokenId);
                } else {
                    safeTransferFrom(from, to, tokenId, "");
                }

            } catch (bytes memory reason) {
                _transfer(from, to, tokenId);
            }
        } else {
            safeTransferFrom(from, to, tokenId, "");
        }
        
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _customMint(address to, uint256 amount) public virtual {
        maxSupply += amount;

        for (uint256 i; i < amount; i++) {
            _mint(to, counter++);
        }
    }

    function _customMaxSupply() public virtual view returns (uint256) {
        return maxSupply;
    }
}

contract TestHarness is CryticERC721ExternalPropertyTests {

    constructor() {
        token = IERC721Internal(address(new ERC721ShouldRevert()));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }

}