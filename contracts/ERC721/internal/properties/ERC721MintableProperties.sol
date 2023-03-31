pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";

abstract contract CryticERC721MintableProperties is CryticERC721TestBase {


    ////////////////////////////////////////
    // Properties
    // mint increases the total supply
    function test_ERC721_mintIncreasesSupply(uint256 amount) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        uint256 oldTotalSupply = totalSupply();
        _customMint(amount);
        
        assertEq(oldTotalSupply + amount, totalSupply(), "Total supply was not correctly increased");
        assertEq(selfBalance + amount, balanceOf(msg.sender), "Receiver supply was not correctly increased");
    }

    // mint creates a fresh token
    function test_ERC721_mintCreatesFreshToken(uint256 amount) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender);
        uint256 endIndex = selfBalance + amount;
        _customMint(amount);

        assertEq(selfBalance + amount, balanceOf(msg.sender), "Receiver supply was not correctly increased");

        for(uint256 i = selfBalance; i < endIndex; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            assertWithMsg(ownerOf(tokenId) == msg.sender, "Token ID was not minted to receiver");
        }
    }

    // the total supply should never be larger than the max supply
    function test_ERC721_totalSupplyShouldNotBeLargerThanMax() public virtual {
        require(hasMaxSupply);
        uint256 max = _customMaxSupply();
        uint256 total = totalSupply();

        assertWithMsg(total <= max, "Total supply larger than max");
    }

    // Wrappers
    function _customMint(uint256 amount) internal virtual;
    function _customMaxSupply() internal virtual view returns (uint256);
}
