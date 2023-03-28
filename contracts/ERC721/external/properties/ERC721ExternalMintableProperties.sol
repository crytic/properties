pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";

abstract contract CryticERC721ExternalMintableProperties is CryticERC721ExternalTestBase {
    using Address for address;

    constructor() {
    }

    ////////////////////////////////////////
    // Properties
    // mint increases the total supply
    function test_ERC721_external_mintIncreasesSupply(uint256 amount) public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        uint256 oldTotalSupply = token.totalSupply();
        _customMint(amount);
        
        assertEq(oldTotalSupply + amount, token.totalSupply(), "Total supply was not correctly increased");
        assertEq(selfBalance + amount, token.balanceOf(msg.sender), "Receiver supply was not correctly increased");
    }

    // mint creates a fresh token
    function test_ERC721_external_mintCreatesFreshToken(uint256 amount) public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender);
        uint256 endIndex = selfBalance + amount;
        _customMint(amount);

        for(uint256 i = selfBalance; i < endIndex; i++) {
            uint256 tokenId = token.tokenOfOwnerByIndex(msg.sender, i);
            assertWithMsg(token.ownerOf(tokenId) == msg.sender, "Token ID was not minted to receiver");
        }
        assertEq(selfBalance + amount, token.balanceOf(msg.sender), "Receiver supply was not correctly increased");
    }

    // Wrappers
    function _customMint(uint256 amount) internal virtual;
}
