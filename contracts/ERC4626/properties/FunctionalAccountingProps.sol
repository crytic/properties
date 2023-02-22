pragma solidity ^0.8.0;

import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";

contract CryticERC4626FunctionalAccounting is CryticERC4626PropertyBase {
    /// @notice Validates the following properties:
    ///  - deposit() must deduct assets from the owner
    ///  - deposit() must credit shares to the receiver
    ///  - deposit() must mint greater than or equal to the number of shares predicted by previewDeposit()
    function verify_depositProperties(uint256 receiverId, uint256 tokens) public {
        address sender = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        tokens = requireValidDepositAmount(sender, receiver, tokens);

        (uint256 senderAssetsBeforeDeposit,) = measureAddressHoldings(sender, "sender", "before deposit");
        (, uint256 receiverSharesBeforeDeposit) = measureAddressHoldings(receiver, "receiver", "before deposit");

        uint256 sharesExpected = vault.previewDeposit(tokens);
        uint256 sharesMinted;
        try vault.deposit(tokens,receiver) returns (uint256 sharesMinted2) {sharesMinted = sharesMinted2;} catch {assert(false);}
        //uint256 sharesMinted = vault.deposit(tokens, receiver);
        assertGte(sharesMinted, sharesExpected, "deposit() must always mint greater than or equal to the shares predicted by previewDeposit()");

        (uint256 senderAssetsAfterDeposit,) = measureAddressHoldings(sender, "sender", "after deposit");
        (, uint256 receiverSharesAfterDeposit) = measureAddressHoldings(receiver, "receiver", "after deposit");
        
        uint256 senderAssetsDelta = senderAssetsBeforeDeposit - senderAssetsAfterDeposit;
        assertEq(senderAssetsDelta, tokens, "deposit() must consume exactly the number of tokens requested");

        uint256 receiverSharesDelta = receiverSharesAfterDeposit - receiverSharesBeforeDeposit;
        assertEq(receiverSharesDelta, sharesMinted, "deposit() must credit the correct number of shares to the receiver");
    }

    /// @notice Validates the following properties:
    ///  - mint() must deduct assets from the owner
    ///  - mint() must credit shares to the receiver
    ///  - mint() must consume less than or equal to the number of assets predicted by previewMint()
    function verify_mintProperties(uint256 receiverId, uint256 shares) public {
        address sender = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        uint256 tokensExpected = vault.previewMint(shares);
        shares = requireValidMintAmount(sender, receiver, shares);

        (uint256 senderAssetsBeforeMint,) = measureAddressHoldings(sender, "sender", "before mint");
        (, uint256 receiverSharesBeforeMint) = measureAddressHoldings(receiver, "receiver", "before mint");

        uint256 tokensConsumed = vault.mint(shares, receiver);
        assertLte(tokensConsumed, tokensExpected, "mint() must always consume less than or equal to the tokens predicted by previewMint()");

        (uint256 senderAssetsAfterMint,) = measureAddressHoldings(sender, "sender", "after mint");
        (, uint256 receiverSharesAfterMint) = measureAddressHoldings(receiver, "receiver", "after mint");

        uint256 senderAssetsDelta = senderAssetsBeforeMint - senderAssetsAfterMint;
        assertEq(senderAssetsDelta, tokensConsumed, "mint() must consume exactly the number of tokens requested");

        uint256 receiverSharesDelta = receiverSharesAfterMint - receiverSharesBeforeMint;
        assertEq(receiverSharesDelta, shares, "mint() must credit the correct number of shares to the receiver");
    }

    /// @notice Validates the following properties:
    ///  - redeem() must deduct shares from the owner
    ///  - redeem() must credit assets to the receiver
    ///  - redeem() must credit greater than or equal to the number of assets predicted by previewRedeem()
    function verify_redeemProperties(uint256 receiverId, uint256 shares) public {
        // we can only redeem on behalf of address(this) until we get cheatcodes
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        shares = requireValidRedeemAmount(owner, shares);

        (, uint256 ownerSharesBefore) = measureAddressHoldings(owner, "owner", "before redeem");
        (uint256 receiverAssetsBefore,) = measureAddressHoldings(receiver, "receiver", "before redeem");

        uint256 tokensExpected = vault.previewRedeem(shares);
        uint256 tokensWithdrawn = vault.redeem(shares, receiver, owner);
        assertGte(tokensWithdrawn, tokensExpected, "redeem() must withdraw greater than or equal to the number of assets predicted by previewRedeem()");

        (, uint256 ownerSharesAfter) = measureAddressHoldings(owner, "owner", "after redeem");
        (uint256 receiverAssetsAfter,) = measureAddressHoldings(receiver, "receiver", "after redeem");

        uint256 receiverAssetsDelta = receiverAssetsAfter - receiverAssetsBefore;
        assertEq(receiverAssetsDelta, tokensWithdrawn, "redeem() must credit the correct number of assets to the receiver");

        uint256 ownerSharesDelta = ownerSharesBefore - ownerSharesAfter;
        assertEq(ownerSharesDelta, shares, "redeem() must deduct the correct number of shares from the owner");
    }

    /// @notice Validates the following properties:
    ///  - withdraw() must deduct shares from the owner
    ///  - withdraw() must credit assets to the receiver
    ///  - withdraw() must deduct less than or equal to the number of shares predicted by previewWithdraw()
    function verify_withdrawProperties(uint256 receiverId, uint256 tokens) public {
        // we can only withdraw on behalf of address(this) until we get cheatcodes
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        tokens = requireValidWithdrawAmount(owner, tokens);
        uint256 sharesExpected = vault.previewWithdraw(tokens);

        (, uint256 ownerSharesBefore) = measureAddressHoldings(owner, "owner", "before withdraw");
        (uint256 receiverAssetsBefore,) = measureAddressHoldings(receiver, "receiver", "before withdraw");

        uint256 sharesRedeemed = vault.withdraw(tokens, receiver, owner);
        assertLte(sharesRedeemed, sharesExpected, "withdraw() must redeem less than or equal to the number of shares predicted by previewWithdraw()");

        (, uint256 ownerSharesAfter) = measureAddressHoldings(owner, "owner", "after withdraw");
        (uint256 receiverAssetsAfter,) = measureAddressHoldings(receiver, "receiver", "after withdraw");

        uint256 receiverAssetsDelta = receiverAssetsAfter - receiverAssetsBefore;
        assertEq(receiverAssetsDelta, tokens, "withdraw() must credit the correct number of assets to the receiver");

        uint256 ownerSharesDelta = ownerSharesBefore - ownerSharesAfter;
        assertEq(ownerSharesDelta, sharesRedeemed, "withdraw() must deduct the correct number of shares from the owner");
    }
}
