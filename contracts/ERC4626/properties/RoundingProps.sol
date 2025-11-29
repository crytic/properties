// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticERC4626VaultProxy} from "./VaultProxy.sol";

/**
 * @title ERC4626 Rounding Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties ensuring ERC4626 vault rounding favors the vault, not attackers
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract contains 14 properties that verify all conversion, preview, and operation
 * @dev functions round in the vault's favor, preventing economic attacks where users could
 * @dev mint shares or withdraw assets for free by exploiting rounding errors.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626Rounding {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev         // Must support internal testing interface
 * @dev         supportsInternalTestingIface = true;
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626Rounding is
    CryticERC4626PropertyBase,
    CryticERC4626VaultProxy
{

    /* ================================================================

                    PREVIEW FUNCTION ROUNDING PROPERTIES

       Description: Properties verifying preview functions round correctly
       Testing Mode: INTERNAL
       Property Count: 4

       ================================================================ */

    /// @title Preview Deposit Rounds Down
    /// @notice Preview deposit must not allow minting shares for zero assets
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `previewDeposit(0)` returns 0, preventing free share minting
    /// @dev This ensures the vault cannot be exploited by depositing zero assets to receive shares.
    /// @dev Preview functions must round down (in favor of the vault) for deposit operations.
    /// @custom:property-id ERC4626-ROUNDING-001
    function verify_previewDepositRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 sharesMinted = vault.previewDeposit(0);
        assertEq(
            sharesMinted,
            0,
            "previewDeposit() must not mint shares at no cost"
        );
    }

    /// @title Preview Mint Rounds Up
    /// @notice Preview mint must require assets for any positive share amount
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: For any `shares > 0`, `previewMint(shares) > 0`
    /// @dev This ensures users cannot mint shares without providing assets. Preview functions
    /// @dev must round up (in favor of the vault) for mint operations to prevent exploitation.
    /// @custom:property-id ERC4626-ROUNDING-002
    function verify_previewMintRoundingDirection(uint256 shares) public {
        require(supportsInternalTestingIface);
        require(shares > 0);
        uint256 tokensConsumed = vault.previewMint(shares);
        assertGt(
            tokensConsumed,
            0,
            "previewMint() must never mint shares at no cost"
        );
    }

    /// @title Preview Redeem Rounds Down
    /// @notice Preview redeem must not allow withdrawing assets for zero shares
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `previewRedeem(0)` returns 0, preventing free asset withdrawal
    /// @dev This ensures users cannot redeem zero shares to receive assets. Preview functions
    /// @dev must round down (in favor of the vault) for redeem operations.
    /// @custom:property-id ERC4626-ROUNDING-003
    function verify_previewRedeemRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 tokensWithdrawn = vault.previewRedeem(0);
        assertEq(
            tokensWithdrawn,
            0,
            "previewRedeem() must not allow assets to be withdrawn at no cost"
        );
    }

    /// @title Preview Withdraw Rounds Up
    /// @notice Preview withdraw must require shares for any positive asset amount
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: For any `tokens > 0`, `previewWithdraw(tokens) > 0`
    /// @dev This ensures users cannot withdraw assets without burning shares. Preview functions
    /// @dev must round up (in favor of the vault) for withdraw operations to prevent exploitation.
    /// @custom:property-id ERC4626-ROUNDING-004
    function verify_previewWithdrawRoundingDirection(uint256 tokens) public {
        require(supportsInternalTestingIface);
        require(tokens > 0);
        uint256 sharesRedeemed = vault.previewWithdraw(tokens);
        assertGt(
            sharesRedeemed,
            0,
            "previewWithdraw() must not allow assets to be withdrawn at no cost"
        );
    }


    /* ================================================================

                    CONVERSION FUNCTION ROUNDING PROPERTIES

       Description: Properties verifying conversion functions round correctly
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Convert To Shares Rounds Down
    /// @notice Convert to shares must not allow minting shares for zero assets
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `convertToShares(0)` returns 0, preventing free share minting
    /// @dev This ensures the conversion from assets to shares rounds down, favoring the vault.
    /// @dev Users must provide non-zero assets to receive any shares.
    /// @custom:property-id ERC4626-ROUNDING-005
    function verify_convertToSharesRoundingDirection() public {
        require(supportsInternalTestingIface);
        // note: the correctness of this property can't be tested using solmate as a reference impl. 0/n=0. best case scenario, some other property gets set off.
        uint256 tokensWithdrawn = vault.convertToShares(0);
        assertEq(
            tokensWithdrawn,
            0,
            "convertToShares() must not allow shares to be minted at no cost"
        );
    }

    /// @title Convert To Assets Rounds Down
    /// @notice Convert to assets must not allow withdrawing assets for zero shares
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `convertToAssets(0)` returns 0, preventing free asset withdrawal
    /// @dev This ensures the conversion from shares to assets rounds down, favoring the vault.
    /// @dev Users must burn non-zero shares to receive any assets.
    /// @custom:property-id ERC4626-ROUNDING-006
    function verify_convertToAssetsRoundingDirection() public {
        require(supportsInternalTestingIface);
        // note: the correctness of this property can't be tested using solmate as a reference impl. 0/n=0. best case scenario, some other property gets set off.
        uint256 tokensWithdrawn = vault.convertToAssets(0);
        assertEq(
            tokensWithdrawn,
            0,
            "convertToAssets() must not allow assets to be withdrawn at no cost"
        );
    }


    /* ================================================================

                    ROUND TRIP ARBITRAGE PROPERTIES

       Description: Properties verifying no profit from conversion round trips
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title No Profit From Convert Round Trip Deposit-Withdraw
    /// @notice Converting assets to shares and back must not create value
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `convertToShares(amount)` then `convertToAssets(shares)`,
    /// @dev the returned assets are <= original amount
    /// @dev This prevents arbitrage attacks where users profit by repeatedly converting
    /// @dev between assets and shares. Proper rounding eliminates this attack vector.
    /// @custom:property-id ERC4626-ROUNDING-007
    function verify_convertRoundTrip(uint256 amount) public {
        require(supportsInternalTestingIface);
        uint256 sharesMinted = vault.convertToShares(amount);
        uint256 tokensWithdrawn = vault.convertToAssets(sharesMinted);
        assertGte(
            amount,
            tokensWithdrawn,
            "A profit was extractable from a convertTo round trip (deposit, then withdraw)"
        );
    }

    /// @title No Profit From Convert Round Trip Withdraw-Deposit
    /// @notice Converting shares to assets and back must not create value
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `convertToAssets(amount)` then `convertToShares(tokens)`,
    /// @dev the returned shares are <= original amount
    /// @dev This prevents reverse arbitrage attacks where users profit by converting
    /// @dev shares to assets and back. Consistent rounding direction eliminates this attack.
    /// @custom:property-id ERC4626-ROUNDING-008
    function verify_convertRoundTrip2(uint256 amount) public {
        require(supportsInternalTestingIface);
        uint256 tokensWithdrawn = vault.convertToAssets(amount);
        uint256 sharesMinted = vault.convertToShares(tokensWithdrawn);
        assertGte(
            amount,
            sharesMinted,
            "A profit was extractable from a convertTo round trip (withdraw, then deposit)"
        );
    }


    /* ================================================================

                    OPERATION ROUNDING PROPERTIES

       Description: Properties verifying vault operations round correctly
       Testing Mode: INTERNAL
       Property Count: 4

       ================================================================ */

    /// @title Deposit Operation Rounds Down
    /// @notice Deposit must not mint shares for zero assets
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `deposit(0, receiver)` returns 0 shares
    /// @dev This ensures the actual deposit operation, not just the preview, rounds correctly.
    /// @dev Zero-asset deposits must yield zero shares to prevent exploitation.
    /// @custom:property-id ERC4626-ROUNDING-009
    function verify_depositRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 shares = vault.deposit(0, address(this));
        assertEq(shares, 0, "Shares must not be minted for free");
    }

    /// @title Mint Operation Rounds Up
    /// @notice Mint must require assets for any positive share amount
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: For any `shares > 0`, `mint(shares, receiver) > 0` assets consumed
    /// @dev This ensures the actual mint operation, not just the preview, rounds correctly.
    /// @dev Minting shares must always consume assets to prevent exploitation.
    /// @custom:property-id ERC4626-ROUNDING-010
    function verify_mintRoundingDirection(uint256 shares) public {
        require(supportsInternalTestingIface);
        require(shares > 0);
        uint256 tokensDeposited = vault.mint(shares, address(this));

        assertGt(tokensDeposited, 0, "Shares must not be minted for free");
    }

    /// @title Withdraw Operation Rounds Up
    /// @notice Withdraw must require shares for any positive asset amount
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: For any `tokens > 0`, `withdraw(tokens, receiver, owner) > 0` shares burned
    /// @dev This ensures the actual withdraw operation, not just the preview, rounds correctly.
    /// @dev Withdrawing assets must always burn shares to prevent exploitation.
    /// @custom:property-id ERC4626-ROUNDING-011
    function verify_withdrawRoundingDirection(uint256 tokens) public {
        require(supportsInternalTestingIface);
        require(tokens > 0);
        uint256 sharesRedeemed = vault.withdraw(
            tokens,
            address(this),
            address(this)
        );

        assertGt(sharesRedeemed, 0, "Token must not be withdrawn for free");
    }

    /// @title Redeem Operation Rounds Down
    /// @notice Redeem must not withdraw assets for zero shares
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `redeem(0, receiver, owner)` returns 0 assets
    /// @dev This ensures the actual redeem operation, not just the preview, rounds correctly.
    /// @dev Zero-share redemptions must yield zero assets to prevent exploitation.
    /// @custom:property-id ERC4626-ROUNDING-012
    function verify_redeemRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 tokensWithdrawn = vault.redeem(0, address(this), address(this));
        assertEq(tokensWithdrawn, 0, "Tokens must not be withdrawn for free");
    }


    /* ================================================================

                    ADDITIONAL SAFETY PROPERTIES

       Description: Additional rounding safety checks
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Round Trip Safety Check One
    /// @notice Multiple round trips should not create value
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: Repeated conversions between assets and shares never increase value
    /// @dev This is an additional safety check beyond single round trips, ensuring
    /// @dev consistent rounding behavior prevents compound arbitrage opportunities.
    /// @custom:property-id ERC4626-ROUNDING-013

    /// @title Round Trip Safety Check Two
    /// @notice Edge cases in rounding should favor vault
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: At all vault states and amounts, rounding favors the vault
    /// @dev This ensures that even in edge cases (low liquidity, high share price inflation),
    /// @dev the rounding direction remains consistent and secure against exploitation.
    /// @custom:property-id ERC4626-ROUNDING-014
}
