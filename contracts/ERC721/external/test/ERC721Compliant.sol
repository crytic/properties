// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {IERC721Internal} from "../../util/IERC721Internal.sol";

contract ERC721Compliant is ERC721, ERC721Enumerable, IERC721Internal {
    
    uint256 public counter;
    bool public isMintableOrBurnable;
    mapping(uint256 => bool) public usedId;

    constructor() ERC721("OZERC721","OZ") {
        isMintableOrBurnable = true;
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    function _customMint(address to, uint256 amount) public virtual {
        for(uint256 i; i < amount; i++) {
            _mint(to, counter++);
        }
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}