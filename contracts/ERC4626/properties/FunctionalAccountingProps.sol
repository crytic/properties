// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";

/**
 * @title ERC4626 Functional Accounting Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC4626 vault deposit, mint, redeem, and withdraw accounting
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract contains 4 properties that test the core accounting mechanics of
 * @dev ERC4626 vaults, ensuring that deposits, mints, redeems, and withdrawals correctly
 * @dev update balances for both assets and shares, and match preview function predictions.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626FunctionalAccounting {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev         // Ensure asset is mintable for testing
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626FunctionalAccounting is CryticERC4626PropertyBase {

    /* ================================================================

                    DEPOSIT AND MINT PROPERTIES

       Description: Properties verifying deposit and mint accounting
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Deposit Updates Balances Correctly
    /// @notice Deposit should deduct assets from sender and credit shares to receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `deposit(tokens, receiver)`, sender's asset balance decreases by `tokens`,
    /// @dev receiver's share balance increases by shares minted, and shares minted >= previewDeposit(tokens)
    /// @dev This ensures accurate accounting during deposits, preventing loss of user funds and
    /// @dev guaranteeing users receive at least the number of shares predicted by the preview function.
    /// @custom:property-id ERC4626-ACCOUNTING-001
    function verify_depositProperties(
        uint256 receiverId,
        uint256 tokens
    ) public {
        address sender = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        tokens = requireValidDepositAmount(sender, receiver, tokens);

        (uint256 senderAssetsBeforeDeposit, ) = measureAddressHoldings(
            sender,
            "sender",
            "before deposit"
        );
        (, uint256 receiverSharesBeforeDeposit) = measureAddressHoldings(
            receiver,
            "receiver",
            "before deposit"
        );

        uint256 sharesExpected = vault.previewDeposit(tokens);
        uint256 sharesMinted = vault.deposit(tokens, receiver);
        assertGte(
            sharesMinted,
            sharesExpected,
            "deposit() must always mint greater than or equal to the shares predicted by previewDeposit()"
        );

        (uint256 senderAssetsAfterDeposit, ) = measureAddressHoldings(
            sender,
            "sender",
            "after deposit"
        );
        (, uint256 receiverSharesAfterDeposit) = measureAddressHoldings(
            receiver,
            "receiver",
            "after deposit"
        );

        uint256 senderAssetsDelta = senderAssetsBeforeDeposit -
            senderAssetsAfterDeposit;
        assertEq(
            senderAssetsDelta,
            tokens,
            "deposit() must consume exactly the number of tokens requested"
        );

        uint256 receiverSharesDelta = receiverSharesAfterDeposit -
            receiverSharesBeforeDeposit;
        assertEq(
            receiverSharesDelta,
            sharesMinted,
            "deposit() must credit the correct number of shares to the receiver"
        );
    }

    /// @title Mint Updates Balances Correctly
    /// @notice Mint should deduct assets from sender and credit exact shares to receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `mint(shares, receiver)`, sender's asset balance decreases by assets consumed,
    /// @dev receiver's share balance increases by `shares`, and assets consumed <= previewMint(shares)
    /// @dev This ensures accurate accounting during minting, preventing over-consumption of user assets
    /// @dev and guaranteeing the receiver receives exactly the requested number of shares.
    /// @custom:property-id ERC4626-ACCOUNTING-002
    function verify_mintProperties(uint256 receiverId, uint256 shares) public {
        address sender = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        uint256 tokensExpected = vault.previewMint(shares);
        shares = requireValidMintAmount(sender, receiver, shares);

        (uint256 senderAssetsBeforeMint, ) = measureAddressHoldings(
            sender,
            "sender",
            "before mint"
        );
        (, uint256 receiverSharesBeforeMint) = measureAddressHoldings(
            receiver,
            "receiver",
            "before mint"
        );

        uint256 tokensConsumed = vault.mint(shares, receiver);
        assertLte(
            tokensConsumed,
            tokensExpected,
            "mint() must always consume less than or equal to the tokens predicted by previewMint()"
        );

        (uint256 senderAssetsAfterMint, ) = measureAddressHoldings(
            sender,
            "sender",
            "after mint"
        );
        (, uint256 receiverSharesAfterMint) = measureAddressHoldings(
            receiver,
            "receiver",
            "after mint"
        );

        uint256 senderAssetsDelta = senderAssetsBeforeMint -
            senderAssetsAfterMint;
        assertEq(
            senderAssetsDelta,
            tokensConsumed,
            "mint() must consume exactly the number of tokens requested"
        );

        uint256 receiverSharesDelta = receiverSharesAfterMint -
            receiverSharesBeforeMint;
        assertEq(
            receiverSharesDelta,
            shares,
            "mint() must credit the correct number of shares to the receiver"
        );
    }


    /* ================================================================

                    REDEEM AND WITHDRAW PROPERTIES

       Description: Properties verifying redeem and withdraw accounting
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Redeem Updates Balances Correctly
    /// @notice Redeem should burn shares from owner and credit assets to receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `redeem(shares, receiver, owner)`, owner's share balance decreases by `shares`,
    /// @dev receiver's asset balance increases by assets withdrawn, and assets withdrawn >= previewRedeem(shares)
    /// @dev This ensures accurate accounting during redemptions, preventing loss of user value and
    /// @dev guaranteeing users receive at least the number of assets predicted by the preview function.
    /// @custom:property-id ERC4626-ACCOUNTING-003
    function verify_redeemProperties(
        uint256 receiverId,
        uint256 shares
    ) public {
        // we can only redeem on behalf of address(this) until we get cheatcodes
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        shares = requireValidRedeemAmount(owner, shares);

        (, uint256 ownerSharesBefore) = measureAddressHoldings(
            owner,
            "owner",
            "before redeem"
        );
        (uint256 receiverAssetsBefore, ) = measureAddressHoldings(
            receiver,
            "receiver",
            "before redeem"
        );

        uint256 tokensExpected = vault.previewRedeem(shares);
        uint256 tokensWithdrawn = vault.redeem(shares, receiver, owner);
        assertGte(
            tokensWithdrawn,
            tokensExpected,
            "redeem() must withdraw greater than or equal to the number of assets predicted by previewRedeem()"
        );

        (, uint256 ownerSharesAfter) = measureAddressHoldings(
            owner,
            "owner",
            "after redeem"
        );
        (uint256 receiverAssetsAfter, ) = measureAddressHoldings(
            receiver,
            "receiver",
            "after redeem"
        );

        uint256 receiverAssetsDelta = receiverAssetsAfter -
            receiverAssetsBefore;
        assertEq(
            receiverAssetsDelta,
            tokensWithdrawn,
            "redeem() must credit the correct number of assets to the receiver"
        );

        uint256 ownerSharesDelta = ownerSharesBefore - ownerSharesAfter;
        assertEq(
            ownerSharesDelta,
            shares,
            "redeem() must deduct the correct number of shares from the owner"
        );
    }

    /// @title Withdraw Updates Balances Correctly
    /// @notice Withdraw should burn shares from owner and credit exact assets to receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After `withdraw(tokens, receiver, owner)`, owner's share balance decreases by shares redeemed,
    /// @dev receiver's asset balance increases by `tokens`, and shares redeemed <= previewWithdraw(tokens)
    /// @dev This ensures accurate accounting during withdrawals, preventing over-burning of user shares
    /// @dev and guaranteeing the receiver receives exactly the requested number of assets.
    /// @custom:property-id ERC4626-ACCOUNTING-004
    function verify_withdrawProperties(
        uint256 receiverId,
        uint256 tokens
    ) public {
        // we can only withdraw on behalf of address(this) until we get cheatcodes
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        tokens = requireValidWithdrawAmount(owner, tokens);
        uint256 sharesExpected = vault.previewWithdraw(tokens);

        (, uint256 ownerSharesBefore) = measureAddressHoldings(
            owner,
            "owner",
            "before withdraw"
        );
        (uint256 receiverAssetsBefore, ) = measureAddressHoldings(
            receiver,
            "receiver",
            "before withdraw"
        );

        uint256 sharesRedeemed = vault.withdraw(tokens, receiver, owner);
        assertLte(
            sharesRedeemed,
            sharesExpected,
            "withdraw() must redeem less than or equal to the number of shares predicted by previewWithdraw()"
        );

        (, uint256 ownerSharesAfter) = measureAddressHoldings(
            owner,
            "owner",
            "after withdraw"
        );
        (uint256 receiverAssetsAfter, ) = measureAddressHoldings(
            receiver,
            "receiver",
            "after withdraw"
        );

        uint256 receiverAssetsDelta = receiverAssetsAfter -
            receiverAssetsBefore;
        assertEq(
            receiverAssetsDelta,
            tokens,
            "withdraw() must credit the correct number of assets to the receiver"
        );

        uint256 ownerSharesDelta = ownerSharesBefore - ownerSharesAfter;
        assertEq(
            ownerSharesDelta,
            sharesRedeemed,
            "withdraw() must deduct the correct number of shares from the owner"
        );
    }
}
