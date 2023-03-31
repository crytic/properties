pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";

abstract contract CryticERC721ExternalMintableProperties is CryticERC721ExternalTestBase {
    using Address for address;
    mapping (uint256 => bool) usedId;
    ////////////////////////////////////////
    // Properties
    // mint increases the total supply
    function test_ERC721_external_mintIncreasesSupply(uint256 amount) public virtual {
        require(token.isMintableOrBurnable());
        require(amount > 0);
        uint256 selfBalance = token.balanceOf(address(this));
        uint256 oldTotalSupply = token.totalSupply();
        token._customMint(address(this), amount);

        assertEq(oldTotalSupply + amount, token.totalSupply(), "Total supply was not correctly increased");
        assertEq(selfBalance + amount, token.balanceOf(address(this)), "Receiver supply was not correctly increased");
    }

    // mint creates a fresh token
    function test_ERC721_external_mintCreatesFreshToken(uint256 amount) public virtual {
        require(token.isMintableOrBurnable());
        require(amount > 0);
        uint256 selfBalance = token.balanceOf(address(this));
        uint256 endIndex = selfBalance + amount;
        token._customMint(address(this), amount);

        for(uint256 i = selfBalance; i < endIndex; i++) {
            uint256 tokenId = token.tokenOfOwnerByIndex(address(this), i);
            assertWithMsg(token.ownerOf(tokenId) == address(this), "Token ID was not minted to receiver");
            assertWithMsg(!usedId[tokenId], "Token ID minted is not new");
            usedId[tokenId] = true;
        }

        assertEq(selfBalance + amount, token.balanceOf(address(this)), "Receiver supply was not correctly increased");
    }
}
