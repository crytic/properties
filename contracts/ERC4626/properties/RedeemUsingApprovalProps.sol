pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticERC4626VaultProxy} from "./VaultProxy.sol";

contract CryticERC4626RedeemUsingApproval is
    CryticERC4626PropertyBase,
    CryticERC4626VaultProxy
{
    /// @notice verifies `redeem()` must allow proxies to redeem shares on behalf of the owner using share token approvals
    ///         verifies third party `redeem()` calls must update the msg.sender's allowance
    function verify_redeemViaApprovalProxy(
        uint256 receiverId,
        uint256 shares
    ) public returns (uint256 tokensWithdrawn) {
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        shares = requireValidRedeemAmount(owner, shares);

        vault.approve(address(redemptionProxy), shares);
        measureAddressHoldings(address(this), "vault", "before redeemption");

        try redemptionProxy.redeemOnBehalf(shares, receiver, owner) returns (
            uint256 _tokensWithdrawn
        ) {
            tokensWithdrawn = _tokensWithdrawn;
        } catch {
            assertWithMsg(
                false,
                "vault.redeem() reverted during redeem via approval"
            );
        }

        // verify allowance is updated
        uint256 newAllowance = vault.allowance(owner, address(redemptionProxy));
        assertEq(
            newAllowance,
            0,
            "The vault failed to update the redemption proxy's share allowance"
        );
    }

    /// @notice verifies `withdraw()` must allow proxies to withdraw shares on behalf of the owner using share token approvals
    ///         verifies third party `withdraw()` calls must update the msg.sender's allowance
    function verify_withdrawViaApprovalProxy(
        uint256 receiverId,
        uint256 tokens
    ) public returns (uint256 sharesBurned) {
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        tokens = requireValidWithdrawAmount(owner, tokens);

        uint256 expectedSharesConsumed = vault.previewWithdraw(tokens);
        vault.approve(address(redemptionProxy), expectedSharesConsumed);
        measureAddressHoldings(address(this), "vault", "before withdraw");

        try redemptionProxy.withdrawOnBehalf(tokens, receiver, owner) returns (
            uint256 _sharesBurned
        ) {
            sharesBurned = _sharesBurned;
        } catch {
            assertWithMsg(
                false,
                "vault.withdraw() reverted during withdraw via approval"
            );
        }

        emit LogUint256("withdraw consumed this many shares:", sharesBurned);

        // verify allowance is updated
        uint256 newAllowance = vault.allowance(owner, address(redemptionProxy));
        uint256 expectedAllowance = expectedSharesConsumed - sharesBurned;
        emit LogUint256("Expecting allowance to now be:", expectedAllowance);
        assertEq(
            expectedAllowance,
            newAllowance,
            "The vault failed to update the redemption proxy's share allowance"
        );
    }

    /// @notice verifies third parties must not be able to `withdraw()` tokens on an owner's behalf without a token approval
    function verify_withdrawRequiresTokenApproval(
        uint256 receiverId,
        uint256 tokens,
        uint256 sharesApproved
    ) public {
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        tokens = requireValidWithdrawAmount(owner, tokens);
        uint256 expectedSharesConsumed = vault.previewWithdraw(tokens);
        emit LogUint256(
            "Will attempt to proxy withdraw this many shares:",
            expectedSharesConsumed
        );

        require(sharesApproved < expectedSharesConsumed);
        emit LogUint256("Approving spend of this many shares:", sharesApproved);
        vault.approve(address(redemptionProxy), sharesApproved);

        try redemptionProxy.withdrawOnBehalf(tokens, receiver, owner) returns (
            uint256 _sharesBurned
        ) {
            assertLte(
                _sharesBurned,
                sharesApproved,
                "Redemption proxy must not be able to withdraw more shares than it was approved"
            );
        } catch {}
    }

    /// @notice verifies third parties must not be able to `redeem()` shares on an owner's behalf without a token approval
    function verify_redeemRequiresTokenApproval(
        uint256 receiverId,
        uint256 shares,
        uint256 sharesApproved
    ) public {
        address owner = address(this);
        address receiver = restrictAddressToThirdParties(receiverId);
        shares = requireValidRedeemAmount(owner, shares);
        emit LogUint256(
            "Will attempt to proxy redeem this many shares:",
            shares
        );

        require(sharesApproved < shares);
        emit LogUint256("Approving spend of this many shares:", sharesApproved);
        vault.approve(address(redemptionProxy), sharesApproved);

        try redemptionProxy.redeemOnBehalf(shares, receiver, owner) returns (
            uint256 _sharesBurned
        ) {
            assertLte(
                _sharesBurned,
                sharesApproved,
                "Redemption proxy must not be able to redeem more shares than it was approved"
            );
        } catch {}
    }
}
