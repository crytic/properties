pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ERC721Compliant is ERC721, ERC721Enumerable {
    
    uint256 public counter;
    uint256 public maxSupply;
    bool public isMintableOrBurnable;

    constructor() ERC721("OZERC721","OZ") {
        maxSupply = 100;
        isMintableOrBurnable = true;
    }


    function _customMint(address to) public virtual {
        maxSupply += 1;
        _mint(to, counter++);
    }

    function _customMaxSupply() public virtual view returns (uint256) {
        return maxSupply;
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}