// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";

abstract contract CryticERC721ExternalMintableProperties is
    CryticERC721ExternalTestBase
{
    using Address for address;

    ////////////////////////////////////////
    // Properties
    // mint increases the total supply.
    function test_ERC721_external_mintIncreasesSupply(
        uint256 amount
    ) public virtual {
        require(token.isMintableOrBurnable());

        uint256 selfBalance = token.balanceOf(address(this));
        uint256 oldTotalSupply = token.totalSupply();

        try token._customMint(address(this), amount) {
            assertEq(
                oldTotalSupply + amount,
                token.totalSupply(),
                "Total supply was not correctly increased"
            );
            assertEq(
                selfBalance + amount,
                token.balanceOf(address(this)),
                "Receiver supply was not correctly increased"
            );
        } catch {
            assertWithMsg(false, "Minting unexpectedly reverted");
        }
    }

    // mint creates a fresh token.
    function test_ERC721_external_mintCreatesFreshToken(
        uint256 amount
    ) public virtual {
        require(token.isMintableOrBurnable());

        uint256 selfBalance = token.balanceOf(address(this));
        try token._customMint(address(this), amount) {
            uint256 tokenId = token.tokenOfOwnerByIndex(
                address(this),
                selfBalance
            );
            assertWithMsg(
                token.ownerOf(tokenId) == address(this),
                "Token ID was not minted to receiver"
            );
            assertEq(
                selfBalance + amount,
                token.balanceOf(address(this)),
                "Receiver supply was not correctly increased"
            );
        } catch {
            assertWithMsg(false, "Minting unexpectedly reverted");
        }
    }
}
