pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {CryticERC721InternalPropertyTests} from "../../ERC721InternalPropertyTests.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";


contract ERC721Compliant is CryticERC721InternalPropertyTests {
    
    uint256 public counter;
    uint256 public maxSupply;

    constructor() ERC721("ERC721Compliant","Compliant") {
        isMintableOrBurnable = true;
        maxSupply = 100;
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);

    }

    function mint(uint256 amount) public {
        //require(totalSupply() + amount <= maxSupply);
        for (uint256 i; i < amount; i++) {
            _mint(msg.sender, counter++);
        }
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(CryticERC721InternalPropertyTests)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CryticERC721InternalPropertyTests)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _customMint(uint256 amount) internal virtual override {
        mint(amount);
    }

    function _customMaxSupply() internal virtual override view returns (uint256) {
        return maxSupply;
    }
}