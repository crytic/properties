// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title ERC20 Burnable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with burn functionality
 * @dev Testing Mode: INTERNAL (test harness inherits from token and properties)
 * @dev This contract contains 3 properties that test token burning mechanics,
 * @dev including burn(), burnFrom(), and allowance updates during burns.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyBurnableToken, CryticERC20BurnableProperties {
 * @dev     constructor() {
 * @dev         _mint(USER1, INITIAL_BALANCE);
 * @dev         _mint(USER2, INITIAL_BALANCE);
 * @dev         _mint(USER3, INITIAL_BALANCE);
 * @dev         isMintableOrBurnable = true; // Must be true for burnable tokens
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20BurnableProperties is
    CryticERC20Base,
    ERC20Burnable
{
    constructor() {
        isMintableOrBurnable = true;
    }


    /* ================================================================

                        BURN PROPERTIES

       Description: Properties verifying token burning mechanics
       Testing Mode: INTERNAL
       Property Count: 3

       ================================================================ */

    /// @title Burn Updates Balance and Supply Correctly
    /// @notice Burning tokens should decrease both user balance and total supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burn(amount)`, `balanceOf(burner)` decreases by `amount`
    /// @dev and `totalSupply()` decreases by `amount`
    /// @dev This ensures burned tokens are properly removed from circulation and cannot
    /// @dev be recovered, maintaining accurate accounting of circulating supply.
    /// @custom:property-id ERC20-BURN-001
    function test_ERC20_burn(uint256 amount) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 supply = totalSupply();
        require(balance_sender > 0);
        uint256 burn_amount = amount % (balance_sender + 1);

        this.burn(burn_amount);
        assertEq(
            balanceOf(address(this)),
            balance_sender - burn_amount,
            "Source balance incorrect after burn"
        );
        assertEq(
            totalSupply(),
            supply - burn_amount,
            "Total supply incorrect after burn"
        );
    }

    /// @title BurnFrom Updates Balance and Supply Correctly
    /// @notice Burning tokens via burnFrom should decrease both owner balance and total supply
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burnFrom(owner, amount)`, `balanceOf(owner)` decreases by `amount`
    /// @dev and `totalSupply()` decreases by `amount`
    /// @dev Delegated burning must maintain the same accounting guarantees as direct burning,
    /// @dev ensuring tokens are permanently removed from circulation regardless of burn method.
    /// @custom:property-id ERC20-BURN-002
    function test_ERC20_burnFrom(uint256 amount) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 supply = totalSupply();
        uint256 burn_amount = amount % (balance_sender + 1);

        this.burnFrom(msg.sender, burn_amount);
        assertEq(
            balanceOf(msg.sender),
            balance_sender - burn_amount,
            "Source balance incorrect after burnFrom"
        );
        assertEq(
            totalSupply(),
            supply - burn_amount,
            "Total supply incorrect after burnFrom"
        );
    }

    /// @title BurnFrom Decreases Allowance Correctly
    /// @notice BurnFrom should consume the burner's allowance
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `burnFrom(owner, amount)`, `allowance(owner, burner)` decreases by `amount`
    /// @dev Exception: Allowance of `type(uint256).max` is treated as infinite by some implementations
    /// @dev This prevents unauthorized burning beyond granted allowances. The burner must have
    /// @dev sufficient allowance to burn tokens on behalf of the owner, and that allowance is
    /// @dev consumed during the burn operation (unless infinite allowance is used).
    /// @custom:property-id ERC20-BURN-003
    function test_ERC20_burnFromUpdateAllowance(uint256 amount) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 burn_amount = amount % (balance_sender + 1);

        this.burnFrom(msg.sender, burn_amount);

        // Some implementations treat type(uint256).max as infinite allowance
        if (current_allowance != type(uint256).max) {
            assertEq(
                allowance(msg.sender, address(this)),
                current_allowance - burn_amount,
                "Allowance not updated correctly"
            );
        }
    }
}
