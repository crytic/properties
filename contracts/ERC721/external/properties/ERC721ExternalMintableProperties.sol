pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";

abstract contract CryticERC721ExternalMintableProperties is CryticERC721ExternalTestBase {
    using Address for address;

    ////////////////////////////////////////
    // Properties
    // mint increases the total supply
    function test_ERC721_external_mintIncreasesSupply() public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(address(this));
        uint256 oldTotalSupply = token.totalSupply();

        try token._customMint(address(this)) {
            assertEq(oldTotalSupply + 1, token.totalSupply(), "Total supply was not correctly increased");
            assertEq(selfBalance + 1, token.balanceOf(address(this)), "Receiver supply was not correctly increased");
        } catch {
            assertWithMsg(false, "Minting unexpectedly reverted");
        }
    }

    // mint creates a fresh token
    function test_ERC721_external_mintCreatesFreshToken() public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(address(this));
        try token._customMint(address(this)) {
            uint256 tokenId = token.tokenOfOwnerByIndex(address(this), selfBalance);
            assertWithMsg(token.ownerOf(tokenId) == address(this), "Token ID was not minted to receiver");
            assertWithMsg(!token.usedId(tokenId), "Token ID minted is not new");
            assertEq(selfBalance + 1, token.balanceOf(address(this)), "Receiver supply was not correctly increased");
        } catch {
            assertWithMsg(false, "Minting unexpectedly reverted");
        }
    }
}
