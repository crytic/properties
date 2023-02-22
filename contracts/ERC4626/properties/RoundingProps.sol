pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticERC4626VaultProxy} from "./VaultProxy.sol";

contract CryticERC4626Rounding is CryticERC4626PropertyBase, CryticERC4626VaultProxy {

    /// @notice verifies shares may never be minted for free using previewDeposit()
    function verify_previewDepositRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 sharesMinted = vault.previewDeposit(0);
        assertEq(sharesMinted, 0, "previewDeposit() must not mint shares at no cost");
    }

    /// @notice verifies shares may never be minted for free using previewMint()
    function verify_previewMintRoundingDirection(uint256 shares) public {
        require(supportsInternalTestingIface);
        require(shares > 0);
        uint256 tokensConsumed = vault.previewMint(shares);
        assertGt(tokensConsumed, 0, "previewMint() must never mint shares at no cost");
    }

    /// @notice verifies shares may never be minted for free using convertToShares()
    function verify_convertToSharesRoundingDirection() public {
        require(supportsInternalTestingIface);
        // note: the correctness of this property can't be tested using solmate as a reference impl. 0/n=0. best case scenario, some other property gets set off.
        uint256 tokensWithdrawn = vault.convertToShares(0);
        assertEq(tokensWithdrawn, 0, "convertToShares() must not allow shares to be minted at no cost");
    }

    /// @notice verifies tokens may never be withdrawn for free using previewRedeem()
    function verify_previewRedeemRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 tokensWithdrawn = vault.previewRedeem(0);
        assertEq(tokensWithdrawn, 0, "previewRedeem() must not allow assets to be withdrawn at no cost");
    }

    /// @notice verifies tokens may never be withdrawn for free using previewWithdraw()
    function verify_previewWithdrawRoundingDirection(uint256 tokens) public {
        require(supportsInternalTestingIface);
        require(tokens > 0);
        uint256 sharesRedeemed = vault.previewWithdraw(tokens);
        assertGt(sharesRedeemed, 0, "previewWithdraw() must not allow assets to be withdrawn at no cost");
    }

    /// @notice verifies tokens may never be withdrawn for free using convertToAssets()
    function verify_convertToAssetsRoundingDirection() public {
        require(supportsInternalTestingIface);
        // note: the correctness of this property can't be tested using solmate as a reference impl. 0/n=0. best case scenario, some other property gets set off.
        uint256 tokensWithdrawn = vault.convertToAssets(0);
        assertEq(tokensWithdrawn, 0, "convertToAssets() must not allow assets to be withdrawn at no cost");
    }

    /// @notice Indirectly verifies the rounding direction of convertToShares/convertToAssets is correct by attempting to
    ///         create an arbitrage by depositing, then withdrawing
    function verify_convertRoundTrip(uint256 amount) public {
        require(supportsInternalTestingIface);
        uint256 sharesMinted = vault.convertToShares(amount);
        uint256 tokensWithdrawn = vault.convertToAssets(sharesMinted);
        assertGte(amount, tokensWithdrawn, "A profit was extractable from a convertTo round trip (deposit, then withdraw)");
    }

    /// @notice Indirectly verifies the rounding direction of convertToShares/convertToAssets is correct by attempting to
    ///         create an arbitrage by withdrawing, then depositing
    function verify_convertRoundTrip2(uint256 amount) public {
        require(supportsInternalTestingIface);
        uint256 tokensWithdrawn = vault.convertToAssets(amount);
        uint256 sharesMinted = vault.convertToShares(tokensWithdrawn);
        assertGte(amount, sharesMinted, "A profit was extractable from a convertTo round trip (withdraw, then deposit)");
    }

    /// @notice verifies Shares may never be minted for free using deposit()
    function verify_depositRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 shares = vault.deposit(0, address(this));
        assertEq(shares, 0, "Shares must not be minted for free");
    }

    /// @notice verifies Shares may never be minted for free using mint()
    function verify_mintRoundingDirection(uint256 shares) public {
        require(supportsInternalTestingIface);
        require(shares > 0);
        uint256 tokensDeposited = vault.mint(shares, address(this));

        assertGt(tokensDeposited, 0, "Shares must not be minted for free");
    }

    /// @notice verifies tokens may never be withdrawn for free using withdraw()
    function verify_withdrawRoundingDirection(uint256 tokens) public {
        require(supportsInternalTestingIface);
        require(tokens > 0);
        uint256 sharesRedeemed = vault.withdraw(tokens, address(this), address(this));

        assertGt(sharesRedeemed, 0, "Token must not be withdrawn for free");
    }

    /// @notice verifies tokens may never be withdrawn for free using redeem()
    function verify_redeemRoundingDirection() public {
        require(supportsInternalTestingIface);
        uint256 tokensWithdrawn = vault.redeem(0, address(this), address(this));
        assertEq(tokensWithdrawn, 0, "Tokens must not be withdrawn for free");
    }
}
