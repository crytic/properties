pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../ERC721InternalPropertyTests.sol";

contract ERC721Compliant is ERC721, ERC721Enumerable, CryticERC721InternalPropertyTests {
    
    uint256 public counter;
    uint256 public maxSupply;

    constructor() ERC721("OZERC721","OZ") {
        maxSupply = 100;
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Enumerable, CryticERC721InternalPropertyTests)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, CryticERC721InternalPropertyTests)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _customMint(uint256 amount) internal virtual override {
        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, counter++);
        }
    }

    function _customMaxSupply() internal virtual override view returns (uint256) {
        return maxSupply;
    }
}