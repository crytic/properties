pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";

abstract contract CryticERC721MintableProperties is CryticERC721TestBase {


    ////////////////////////////////////////
    // Properties
    // mint increases the total supply.
    function test_ERC721_mintIncreasesSupply(uint256 amount) public virtual {
        require(isMintableOrBurnable);

        uint256 selfBalance = balanceOf(msg.sender);
        uint256 oldTotalSupply = totalSupply();
        _customMint(msg.sender, amount);
        
        assertEq(oldTotalSupply + amount, totalSupply(), "Total supply was not correctly increased");
        assertEq(selfBalance + amount, balanceOf(msg.sender), "Receiver supply was not correctly increased");
    }

    // mint creates a fresh token.
    function test_ERC721_mintCreatesFreshToken(uint256 amount) public virtual {
        require(isMintableOrBurnable);

        uint256 selfBalance = balanceOf(msg.sender);
        _customMint(msg.sender, amount);

        assertEq(selfBalance + amount, balanceOf(msg.sender), "Receiver supply was not correctly increased");

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, selfBalance);
        assertWithMsg(ownerOf(tokenId) == msg.sender, "Token ID was not minted to receiver");
        
    }

    // Wrappers
    function _customMint(address to, uint256 amount) internal virtual;
}
