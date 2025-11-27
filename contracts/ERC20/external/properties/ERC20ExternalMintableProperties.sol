// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";

/**
 * @title ERC20 External Mintable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with mint functionality tested via external interface
 * @dev Testing Mode: EXTERNAL (test harness interacts with token through external interface)
 * @dev This contract contains 1 property that tests token minting mechanics via external
 * @dev interface. The token's mint() function is called externally to verify proper balance
 * @dev and supply updates.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC20ExternalMintableProperties {
 * @dev     constructor() {
 * @dev         // Deploy or reference your mintable ERC20 token
 * @dev         token = ITokenMock(address(new MyMintableToken()));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20ExternalMintableProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}


    /* ================================================================

                        MINT PROPERTIES

       Description: Properties verifying token minting mechanics
       Testing Mode: EXTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Mint Updates Balance and Supply Correctly
    /// @notice Minting tokens should increase both recipient balance and total supply
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `mint(target, amount)`, `balanceOf(target)` increases by `amount`
    /// @dev and `totalSupply()` increases by `amount`
    /// @dev This ensures minted tokens are properly added to circulation and credited to the
    /// @dev recipient, maintaining accurate accounting of total supply. The relationship between
    /// @dev individual balances and total supply must be preserved during minting. New tokens
    /// @dev are created from nothing and must be reflected in both the recipient's balance and
    /// @dev the total circulating supply.
    /// @custom:property-id ERC20-EXTERNAL-MINT-051
    function test_ERC20external_mintTokens(
        address target,
        uint256 amount
    ) public {
        uint256 balance_receiver = token.balanceOf(target);
        uint256 supply = token.totalSupply();

        token.mint(target, amount);
        assertEq(
            token.balanceOf(target),
            balance_receiver + amount,
            "Mint failed to update target balance"
        );
        assertEq(
            token.totalSupply(),
            supply + amount,
            "Mint failed to update total supply"
        );
    }
}
