// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721TestBase.sol";

/**
 * @title ERC721 Mintable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC721 tokens with mint functionality
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 2 properties that test token minting mechanics,
 * @dev including supply updates and token ownership after minting.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyMintableERC721Token, CryticERC721MintableProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, 1);
 * @dev         _mint(USER2, 2);
 * @dev         _mint(USER3, 3);
 * @dev         isMintableOrBurnable = true; // Must be true for mintable tokens
 * @dev     }
 * @dev
 * @dev     function _customMint(address to, uint256 amount) internal override {
 * @dev         for (uint256 i = 0; i < amount; i++) {
 * @dev             _mint(to, nextTokenId++);
 * @dev         }
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC721MintableProperties is CryticERC721TestBase {

    /* ================================================================

                        MINT PROPERTIES

       Description: Properties verifying token minting mechanics
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Mint Increases Total Supply
    /// @notice Minting tokens should increase the total supply correctly
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After minting `amount` tokens, `totalSupply()` increases by `amount`
    /// @dev and `balanceOf(recipient)` increases by `amount`
    /// @dev Newly minted tokens must be properly accounted for in both the total supply
    /// @dev and the recipient's balance. This ensures the token supply accurately reflects
    /// @dev all existing tokens and balances are updated correctly.
    /// @custom:property-id ERC721-MINT-001
    function test_ERC721_mintIncreasesSupply(uint256 amount) public virtual {
        require(isMintableOrBurnable);

        uint256 selfBalance = balanceOf(msg.sender);
        uint256 oldTotalSupply = totalSupply();
        _customMint(msg.sender, amount);

        assertEq(oldTotalSupply + amount, totalSupply(), "Total supply was not correctly increased");
        assertEq(selfBalance + amount, balanceOf(msg.sender), "Receiver supply was not correctly increased");
    }

    /// @title Mint Creates Valid Token With Correct Owner
    /// @notice Newly minted tokens should have the recipient as owner
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After minting tokens to `recipient`, the new tokens exist and
    /// @dev `ownerOf(newTokenId)` returns `recipient`
    /// @dev Minting must create valid, owned tokens. The newly minted token must be
    /// @dev queryable and must belong to the intended recipient, establishing proper
    /// @dev initial ownership for each minted token.
    /// @custom:property-id ERC721-MINT-002
    function test_ERC721_mintCreatesFreshToken(uint256 amount) public virtual {
        require(isMintableOrBurnable);

        uint256 selfBalance = balanceOf(msg.sender);
        _customMint(msg.sender, amount);

        assertEq(selfBalance + amount, balanceOf(msg.sender), "Receiver supply was not correctly increased");

        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, selfBalance);
        assertWithMsg(ownerOf(tokenId) == msg.sender, "Token ID was not minted to receiver");

    }

    /// @dev Wrapper function to be implemented by test harness
    /// @dev This should call the token's internal mint function
    function _customMint(address to, uint256 amount) internal virtual;
}
