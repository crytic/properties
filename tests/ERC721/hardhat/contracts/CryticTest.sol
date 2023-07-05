pragma solidity ^0.8.0;
import "@crytic/properties/contracts/ERC721/internal/properties/ERC721BasicProperties.sol";
import "./ExampleToken.sol";

contract CryticERC721InternalHarness is ExampleToken, CryticERC721BasicProperties {
    using Address for address;

    constructor() {
        isMintableOrBurnable = true;
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
    }

    function _customMint(address to, uint256 amount) internal virtual {
        mint(to, amount);
    }

        // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ExampleToken, CryticERC721TestBase)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ExampleToken, CryticERC721TestBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
