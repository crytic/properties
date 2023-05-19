pragma solidity ^0.8.0;

import {IERC20} from "../../util/IERC20.sol";
import {IERC4626} from "../../util/IERC4626.sol";
import {TestERC20Token} from "./TestERC20Token.sol";
import {Actor} from "../util/Actor.sol";
import {PropertiesAsserts} from "../../util/PropertiesHelper.sol";
import {RedemptionProxy} from "./RedemptionProxy.sol";

/// @notice This contract is used as a base contract for all 4626 property tests.
contract CryticERC4626PropertyBase is PropertiesAsserts {
    TestERC20Token asset;
    IERC4626 vault;

    Actor alice;
    Actor bob; //remove?

    RedemptionProxy redemptionProxy;

    // feature flags
    bool supportsInternalTestingIface;

    function initialize(
        address _vault,
        address _asset,
        bool _supportsInternalTestingIface
    ) internal {
        vault = IERC4626(_vault);
        asset = TestERC20Token(_asset);
        alice = new Actor(vault);
        bob = new Actor(vault);
        redemptionProxy = new RedemptionProxy(vault);
        supportsInternalTestingIface = _supportsInternalTestingIface;
    }

    /// @notice Funds the `owner` address with `tokens` & forces a token approval for the vault to spend owner's tokens.
    function prepareAddressForDeposit(address owner, uint256 tokens) internal {
        asset.mint(owner, tokens);
        asset.forceApproval(owner, address(vault), tokens);
    }

    /// @notice Measures the `target`'s assets and shares, and emits events to assist in debugging property failures.
    /// @param target A address to target
    /// @param name A name for the target address (alice, bob, vault, etc.)
    /// @param annotation An additional piece of metadata for debugging ie: "before deposit", "after mint", etc.
    function measureAddressHoldings(
        address target,
        string memory name,
        string memory annotation
    ) internal returns (uint256 assetBalance, uint256 shareBalance) {
        assetBalance = asset.balanceOf(target);
        shareBalance = vault.balanceOf(target);

        string memory assetMsg = string(
            abi.encodePacked("asset.balanceOf(", name, ") (", annotation, ")")
        );
        emit LogUint256(assetMsg, assetBalance);
        string memory shareMsg = string(
            abi.encodePacked("vault.balanceOf(", name, ") (", annotation, ")")
        );
        emit LogUint256(shareMsg, shareBalance);
    }

    /// @notice Prevents `party` from resolving to addresses which have special accounting rules.
    function restrictAddressToThirdParties(
        uint256 partyIndex
    ) internal view returns (address) {
        // set up 3 static third parties
        partyIndex = partyIndex % 3;
        if (partyIndex == 0) {
            return address(this);
        }
        if (partyIndex == 1) {
            return 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
        }
        return 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
    }

    /// @notice Performs all the checks required to ensure a successful vault deposit. This includes funding the owner account and clamping token amounts as needed.
    ///         It is assumed that successful calls to requireValidDepositAmount imply that vault.deposit() will not revert. This implied property might not hold for certain
    ///         vault implementations, and should be modified if exceptions are discovered.
    function requireValidDepositAmount(
        address owner,
        address receiver,
        uint256 tokens
    ) internal returns (uint256) {
        tokens = clampLte(tokens, vault.maxDeposit(receiver));
        tokens = clampGt(tokens, 0);
        prepareAddressForDeposit(owner, tokens);

        // The following logic is intended to revert when an unreasonably large deposit is being made.
        uint256 sharesMinted = vault.convertToShares(tokens);
        uint256 currentShares = vault.balanceOf(receiver);
        vault.convertToAssets(sharesMinted + currentShares);
        //uint256 sharesRedeemed = vault.previewWithdraw(tokensWithdrawn);
        emit LogUint256("Tokens to use in deposit:", tokens);

        // configure with setting?
        require(vault.previewDeposit(tokens) > 0);
        return tokens;
    }

    /// @notice Performs all the checks required to ensure a successful vault mint. This includes funding the owner account and clamping token amounts as needed.
    ///         It is assumed that successful calls to requireValidDepositAmount imply that vault.mint() will not revert. This implied property might not hold for certain
    ///         vault implementations, and should be modified if exceptions are discovered.
    function requireValidMintAmount(
        address owner,
        address receiver,
        uint256 shares
    ) internal returns (uint256) {
        shares = clampLte(shares, vault.maxMint(receiver));
        uint256 tokensDeposited = vault.previewMint(shares);
        prepareAddressForDeposit(owner, tokensDeposited);

        // The following logic is intended to revert when an unreasonably large mint is being made.
        uint256 currentShares = vault.balanceOf(receiver);
        vault.previewRedeem(currentShares + shares);
        emit LogUint256("Shares to use in mint:", shares);

        // configure with setting?
        // require(vault.previewMint(shares) > 0);
        return shares;
    }

    /// @notice Performs all the checks required to ensure a successful vault redeem. This includes funding the owner account and clamping token amounts as needed.
    ///         It is assumed that successful calls to requireValidDepositAmount imply that vault.redeem() will not revert. This implied property might not hold for certain
    ///         vault implementations, and should be modified if exceptions are discovered.
    function requireValidRedeemAmount(
        address owner,
        uint256 shares
    ) internal returns (uint256) {
        // should this be a configured setting?
        require(shares > 0);

        uint256 maxRedeem = vault.maxRedeem(owner);
        require(maxRedeem > 0);
        uint256 ownerShares = vault.balanceOf(owner);
        require(ownerShares > 0);

        shares = clampLte(shares, maxRedeem);
        shares = clampLte(shares, ownerShares);

        // The following logic is intended to revert when an unreasonably large redemption is being made.
        uint256 tokensWithdrawn = vault.convertToAssets(shares);
        vault.previewRedeem(shares);
        // should this be a configured setting?
        require(tokensWithdrawn > 0);
        emit LogUint256("Shares to use in redemption:", shares);
        return shares;
    }

    /// @notice Performs all the checks required to ensure a successful vault withdraw. This includes funding the owner account and clamping token amounts as needed.
    ///         It is assumed that successful calls to requireValidDepositAmount imply that vault.withdraw() will not revert. This implied property might not hold for certain
    ///         vault implementations, and should be modified if exceptions are discovered.
    function requireValidWithdrawAmount(
        address owner,
        uint256 tokens
    ) internal returns (uint256) {
        uint256 maxWithdraw = vault.maxWithdraw(owner);
        require(maxWithdraw > 0);

        uint256 ownerBalance = vault.balanceOf(owner);
        require(ownerBalance > 0);

        uint256 sharesToRedeem = vault.previewWithdraw(tokens);
        sharesToRedeem = clampLte(sharesToRedeem, vault.balanceOf(owner));
        require(sharesToRedeem <= ownerBalance);

        // not easy to clamp these without making this code a lot more complex.
        uint256 clampedTokens = vault.previewRedeem(sharesToRedeem);
        require(clampedTokens <= maxWithdraw);
        // should this be a configured setting?
        sharesToRedeem = vault.previewWithdraw(clampedTokens);
        require(sharesToRedeem > 0);

        // we don't need to check for unreasonably large withdraws because previewWithdraw would have reverted.
        emit LogUint256("Tokens to use in withdraw:", clampedTokens);
        return clampedTokens;
    }
}
