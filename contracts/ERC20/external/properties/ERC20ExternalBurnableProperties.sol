// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";

/**
 * @title ERC20 External Burnable Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC20 tokens with burn functionality tested via external interface
 * @dev Testing Mode: EXTERNAL (test harness interacts with token through external interface)
 * @dev This contract contains 3 properties that test token burning mechanics via external
 * @dev interface, including burn(), burnFrom(), and allowance updates during burns.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is CryticERC20ExternalBurnableProperties {
 * @dev     constructor() {
 * @dev         // Deploy or reference your burnable ERC20 token
 * @dev         token = ITokenMock(address(new MyBurnableToken()));
 * @dev     }
 * @dev }
 * @dev ```
 */
abstract contract CryticERC20ExternalBurnableProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}


    /* ================================================================

                        BURN PROPERTIES

       Description: Properties verifying token burning mechanics
       Testing Mode: EXTERNAL
       Property Count: 3

       ================================================================ */

    /// @title Burn Updates Balance and Supply Correctly
    /// @notice Burning tokens should decrease both user balance and total supply
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `burn(amount)`, `balanceOf(burner)` decreases by `amount`
    /// @dev and `totalSupply()` decreases by `amount`
    /// @dev This ensures burned tokens are properly removed from circulation and cannot
    /// @dev be recovered, maintaining accurate accounting of circulating supply. The burn
    /// @dev operation permanently destroys tokens, reducing both individual balance and
    /// @dev the total token supply by exactly the burned amount.
    /// @custom:property-id ERC20-EXTERNAL-BURN-051
    function test_ERC20external_burn(uint256 amount) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 supply = token.totalSupply();
        require(balance_sender > 0);
        uint256 burn_amount = amount % (balance_sender + 1);

        token.burn(burn_amount);
        assertEq(
            token.balanceOf(address(this)),
            balance_sender - burn_amount,
            "Source balance incorrect after burn"
        );
        assertEq(
            token.totalSupply(),
            supply - burn_amount,
            "Total supply incorrect after burn"
        );
    }

    /// @title BurnFrom Updates Balance and Supply Correctly
    /// @notice Burning tokens via burnFrom should decrease both owner balance and total supply
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `burnFrom(owner, amount)`, `balanceOf(owner)` decreases by `amount`
    /// @dev and `totalSupply()` decreases by `amount`
    /// @dev Delegated burning must maintain the same accounting guarantees as direct burning,
    /// @dev ensuring tokens are permanently removed from circulation regardless of burn method.
    /// @dev The burner must have sufficient allowance from the owner to burn tokens on their behalf.
    /// @custom:property-id ERC20-EXTERNAL-BURN-052
    function test_ERC20external_burnFrom(uint256 amount) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 supply = token.totalSupply();
        uint256 burn_amount = amount % (balance_sender + 1);

        token.burnFrom(msg.sender, burn_amount);
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender - burn_amount,
            "Source balance incorrect after burnFrom"
        );
        assertEq(
            token.totalSupply(),
            supply - burn_amount,
            "Total supply incorrect after burnFrom"
        );
    }

    /// @title BurnFrom Decreases Allowance Correctly
    /// @notice BurnFrom should consume the burner's allowance
    /// @dev Testing Mode: EXTERNAL
    /// @dev Invariant: After `burnFrom(owner, amount)`, `allowance(owner, burner)` decreases by `amount`
    /// @dev Exception: Allowance of `type(uint256).max` is treated as infinite by some implementations
    /// @dev This prevents unauthorized burning beyond granted allowances. The burner must have
    /// @dev sufficient allowance to burn tokens on behalf of the owner, and that allowance is
    /// @dev consumed during the burn operation (unless infinite allowance is used). This ensures
    /// @dev burn permissions are properly enforced through the allowance mechanism.
    /// @custom:property-id ERC20-EXTERNAL-BURN-053
    function test_ERC20external_burnFromUpdateAllowance(uint256 amount) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 current_allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 burn_amount = amount % (balance_sender + 1);

        token.burnFrom(msg.sender, burn_amount);

        // Some implementations take an allowance of 2**256-1 as infinite, and therefore don't update
        if (current_allowance != type(uint256).max) {
            assertEq(
                token.allowance(msg.sender, address(this)),
                current_allowance - burn_amount,
                "Allowance not updated correctly"
            );
        }
    }
}
