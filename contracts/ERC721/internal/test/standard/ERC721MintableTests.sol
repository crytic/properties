// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {CryticERC721MintableProperties} from "../../properties/ERC721MintableProperties.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC721MintableTestsInternal is CryticERC721MintableProperties {
    using Address for address;
    
    uint256 public counter;

    constructor() ERC721("ERC721BasicTestsInternal","ERC721BasicTestsInternal") {
        isMintableOrBurnable = true;
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
    }

    function mint(address to) public {
        //require(totalSupply() + amount <= maxSupply);
        /* for (uint256 i; i < amount; i++) {
            _mint(msg.sender, counter++);
        } */
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
        }
        _approve(address(this), tokenId);
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
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _customMint(address to, uint256 amount) internal virtual override {
        for(uint256 i; i < amount; i++) {
            mint(to);
        }
    }
}

contract TestHarness is ERC721MintableTestsInternal {
    constructor() {}
}