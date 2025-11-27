// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";

/**
 * @title ERC4626 Sender Independent Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties ensuring ERC4626 view functions are independent of caller state
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract contains 6 properties that verify preview, max, and conversion functions
 * @dev return consistent results regardless of the caller's asset balance. These functions
 * @dev must be stateless with respect to msg.sender for proper integration behavior.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626SenderIndependent {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev         // Asset must be mintable for testing
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626SenderIndependent is CryticERC4626PropertyBase {
    // todo: these properties may have issues in vaults that have super weird redemption curves.
    // If that happens, use a proxy contract to compare results instead of msg.sender's state


    /* ================================================================

                    MAX OPERATION INDEPENDENCE PROPERTIES

       Description: Properties verifying max functions ignore sender balance
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Max Deposit Ignores Sender Assets
    /// @notice The maxDeposit result should not depend on sender's asset balance
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `maxDeposit(receiver)` returns the same value before and after
    /// @dev minting assets to the receiver
    /// @dev This ensures maxDeposit assumes infinite available assets as per ERC4626 spec,
    /// @dev allowing integrations to determine vault-side limits without considering user balances.
    /// @custom:property-id ERC4626-INDEPENDENCE-001
    function verify_maxDepositIgnoresSenderAssets(uint256 tokens) public {
        address receiver = address(this);
        uint256 maxDepositBefore = vault.maxDeposit(receiver);
        asset.mint(receiver, tokens);
        uint256 maxDepositAfter = vault.maxDeposit(receiver);
        assertEq(
            maxDepositBefore,
            maxDepositAfter,
            "maxDeposit must assume the agent has infinite assets"
        );
    }

    /// @title Max Mint Ignores Sender Assets
    /// @notice The maxMint result should not depend on sender's asset balance
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `maxMint(receiver)` returns the same value before and after
    /// @dev minting assets to the receiver
    /// @dev This ensures maxMint assumes infinite available assets as per ERC4626 spec,
    /// @dev allowing integrations to determine vault-side share limits independently.
    /// @custom:property-id ERC4626-INDEPENDENCE-002
    function verify_maxMintIgnoresSenderAssets(uint256 tokens) public {
        address receiver = address(this);
        uint256 maxMintBefore = vault.maxMint(receiver);
        asset.mint(receiver, tokens);
        uint256 maxMintAfter = vault.maxMint(receiver);
        assertEq(
            maxMintBefore,
            maxMintAfter,
            "maxMint must assume the agent has infinite assets"
        );
    }


    /* ================================================================

                    PREVIEW DEPOSIT INDEPENDENCE PROPERTIES

       Description: Properties verifying preview deposit functions ignore sender
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Preview Mint Ignores Sender
    /// @notice The previewMint result should not depend on msg.sender
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `previewMint(shares)` returns the same value before and after
    /// @dev changing msg.sender's asset balance
    /// @dev This ensures preview functions provide consistent estimates regardless of caller,
    /// @dev which is critical for integrations and UI calculations to work correctly.
    /// @custom:property-id ERC4626-INDEPENDENCE-003
    function verify_previewMintIgnoresSender(
        uint256 tokens,
        uint256 shares
    ) public {
        address receiver = address(this);
        uint256 assetsExpectedBefore = vault.previewMint(shares);
        prepareAddressForDeposit(receiver, tokens);

        uint256 assetsExpectedAfter = vault.previewMint(shares);
        assertEq(
            assetsExpectedBefore,
            assetsExpectedAfter,
            "previewMint must not be dependent on msg.sender"
        );
    }

    /// @title Preview Deposit Ignores Sender
    /// @notice The previewDeposit result should not depend on msg.sender
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `previewDeposit(tokens)` returns the same value before and after
    /// @dev changing msg.sender's asset balance
    /// @dev This ensures deposit previews are purely a function of vault state and amount,
    /// @dev not affected by the caller's balance, enabling accurate off-chain calculations.
    /// @custom:property-id ERC4626-INDEPENDENCE-004
    function verify_previewDepositIgnoresSender(uint256 tokens) public {
        address receiver = address(this);
        uint256 sharesExpectedBefore = vault.previewDeposit(tokens);
        prepareAddressForDeposit(receiver, tokens);

        uint256 sharesExpectedAfter = vault.previewDeposit(tokens);
        assertEq(
            sharesExpectedBefore,
            sharesExpectedAfter,
            "previewDeposit must not be dependent on msg.sender"
        );
    }


    /* ================================================================

                    PREVIEW WITHDRAW INDEPENDENCE PROPERTIES

       Description: Properties verifying preview withdraw functions ignore sender
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Preview Withdraw Ignores Sender
    /// @notice The previewWithdraw result should not depend on msg.sender
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `previewWithdraw(tokens)` returns the same value before and after
    /// @dev depositing assets and receiving shares
    /// @dev This ensures withdrawal previews are purely a function of vault state and amount,
    /// @dev allowing accurate cost estimation regardless of the caller's position.
    /// @custom:property-id ERC4626-INDEPENDENCE-005
    function verify_previewWithdrawIgnoresSender(uint256 tokens) public {
        address receiver = address(this);
        uint256 sharesExpectedBefore = vault.previewWithdraw(tokens);
        prepareAddressForDeposit(receiver, tokens);

        vault.deposit(tokens, receiver);

        uint256 sharesExpectedAfter = vault.previewWithdraw(tokens);
        assertEq(
            sharesExpectedBefore,
            sharesExpectedAfter,
            "previewWithdraw must not be dependent on msg.sender"
        );

        // keep this property relatively stateless
        vault.redeem(vault.balanceOf(receiver), receiver, receiver);
    }

    /// @title Preview Redeem Ignores Sender
    /// @notice The previewRedeem result should not depend on msg.sender
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `previewRedeem(shares)` returns the same value before and after
    /// @dev depositing assets and receiving shares
    /// @dev This ensures redemption previews are purely a function of vault state and share amount,
    /// @dev enabling consistent value calculations for all users regardless of their holdings.
    /// @custom:property-id ERC4626-INDEPENDENCE-006
    function verify_previewRedeemIgnoresSender(uint256 shares) public {
        address receiver = address(this);
        uint256 tokensExpectedBefore = vault.previewRedeem(shares);

        uint256 assetsToDeposit = vault.previewMint(shares);
        prepareAddressForDeposit(receiver, assetsToDeposit);

        vault.deposit(assetsToDeposit, receiver);

        uint256 tokensExpectedAfter = vault.previewRedeem(shares);
        assertEq(
            tokensExpectedBefore,
            tokensExpectedAfter,
            "previewRedeem must not be dependent on msg.sender"
        );

        // keep this property relatively stateless
        vault.redeem(vault.balanceOf(receiver), receiver, receiver);
    }


    /* ================================================================

                    ADDITIONAL INDEPENDENCE PROPERTIES

       Description: Additional statelessness verification
       Testing Mode: INTERNAL
       Property Count: 0

       ================================================================ */

    /// @dev Additional properties can verify that conversion functions (convertToShares,
    /// @dev convertToAssets) are also independent of msg.sender, though these are typically
    /// @dev implemented as pure functions of vault state and thus inherently independent.
}
