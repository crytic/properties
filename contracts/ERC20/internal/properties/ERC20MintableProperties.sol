// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";

/**
 * @title ERC20 Mintable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with mint functionality
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 1 property that tests token minting mechanics.
 * @dev The mint() function must be overridden to match your token's minting function name.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyMintableToken, CryticERC20MintableProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         _mint(USER2, INITIAL_BALANCE);
 * @dev         _mint(USER3, INITIAL_BALANCE);
 * @dev         isMintableOrBurnable = true; // Must be true for mintable tokens
 * @dev     }
 * @dev
 * @dev     // Override to match your token's mint function
 * @dev     function mint(address to, uint256 amount) public override {
 * @dev         _mint(to, amount);
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20MintableProperties is CryticERC20Base {
    constructor() {
        isMintableOrBurnable = true;
    }

    /// @notice Override this function to match your token's minting function name
    /// @dev If your token uses a different function name (e.g., mintTokens), override this
    function mint(address to, uint256 amount) public virtual;


    /* ================================================================

                        MINT PROPERTIES

       Description: Properties verifying token minting mechanics
       Testing Mode: INTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Mint Updates Balance and Supply Correctly
    /// @notice Minting tokens should increase both recipient balance and total supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `mint(target, amount)`, `balanceOf(target)` increases by `amount`
    /// @dev and `totalSupply()` increases by `amount`
    /// @dev This ensures minted tokens are properly added to circulation and credited to the
    /// @dev recipient, maintaining accurate accounting of total supply. The relationship between
    /// @dev individual balances and total supply must be preserved during minting.
    /// @custom:property-id ERC20-MINT-001
    function test_ERC20_mintTokens(address target, uint256 amount) public {
        uint256 balance_receiver = balanceOf(target);
        uint256 supply = totalSupply();

        this.mint(target, amount);
        assertEq(
            balanceOf(target),
            balance_receiver + amount,
            "Mint failed to update target balance"
        );
        assertEq(
            totalSupply(),
            supply + amount,
            "Mint failed to update total supply"
        );
    }
}
