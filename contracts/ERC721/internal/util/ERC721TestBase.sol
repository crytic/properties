pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesHelper.sol";
import {MockReceiver} from "./MockReceiver.sol";

abstract contract CryticERC721TestBase is ERC721, ERC721Enumerable, PropertiesAsserts, PropertiesConstants {

    // Is the contract allowed to change its total supply?
    bool isMintableOrBurnable;
    bool hasMaxSupply;
    uint256 maxSupply;
    MockReceiver safeReceiver;
    MockReceiver unsafeReceiver;

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
