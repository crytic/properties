pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {CryticERC721ExternalPropertyTests} from "../../ERC721ExternalPropertyTests.sol";
import {IERC721Mock} from "../../util/IERC721Mock.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC721ShouldRevert is ERC721, ERC721Enumerable {
    
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
        // removed validation

        _approve(to, tokenId);
        

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

    function _customMint(uint256 amount) public virtual {
        for (uint256 i; i < amount; i++) {
            _mint(msg.sender, counter++);
        }
    }

    function _customMaxSupply() public virtual view returns (uint256) {
        return maxSupply;
    }
}

contract TestHarness is CryticERC721ExternalPropertyTests {

    constructor() {
        token = IERC721Mock(address(new ERC721ShouldRevert()));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }

    function _customMint(uint256 amount) internal virtual override {}

}