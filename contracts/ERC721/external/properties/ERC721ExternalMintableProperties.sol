// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC721ExternalTestBase.sol";

/**
 * @title ERC721 External Mintable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC721 tokens with mint functionality
 * @dev Testing Mode: EXTERNAL (test harness calls token through external interface)
 * @dev This contract contains 2 properties that test token minting mechanics,
 * @dev including supply updates and token ownership after minting.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC721ExternalMintableProperties {
 * @dev     constructor() {
 * @dev         // Deploy the actual token contract
 * @dev         MyMintableERC721Token tokenContract = new MyMintableERC721Token();
 * @dev         tokenContract.mint(USER1, 1);
 * @dev         tokenContract.mint(USER2, 2);
 * @dev         tokenContract.mint(USER3, 3);
 * @dev
 * @dev         // Initialize the properties contract with token address
 * @dev         initialize(address(tokenContract));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC721ExternalMintableProperties is
    CryticERC721ExternalTestBase
{
    using Address for address;

    /* ================================================================

                        MINT PROPERTIES

       Description: Properties verifying token minting mechanics
       Testing Mode: EXTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Mint Increases Total Supply
    /// @notice Minting tokens should increase the total supply correctly
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After minting `amount` tokens, `totalSupply()` increases by `amount`
    /// @dev and `balanceOf(recipient)` increases by `amount`
    /// @dev Newly minted tokens must be properly accounted for in both the total supply
    /// @dev and the recipient's balance. This ensures the token supply accurately reflects
    /// @dev all existing tokens and balances are updated correctly.
    /// @custom:property-id ERC721-EXTERNAL-MINT-051
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

    /// @title Mint Creates Valid Token With Correct Owner
    /// @notice Newly minted tokens should have the recipient as owner
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After minting tokens to `recipient`, the new tokens exist and
    /// @dev `ownerOf(newTokenId)` returns `recipient`
    /// @dev Minting must create valid, owned tokens. The newly minted token must be
    /// @dev queryable and must belong to the intended recipient, establishing proper
    /// @dev initial ownership for each minted token.
    /// @custom:property-id ERC721-EXTERNAL-MINT-052
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
