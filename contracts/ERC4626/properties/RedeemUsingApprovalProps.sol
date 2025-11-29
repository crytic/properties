// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticERC4626VaultProxy} from "./VaultProxy.sol";

/**
 * @title ERC4626 Redeem Using Approval Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties for ERC4626 vault approval-based redemptions and withdrawals
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract contains 4 properties that test the approval mechanism for third-party
 * @dev redemptions and withdrawals. These properties ensure that proxies can only redeem or
 * @dev withdraw shares with proper ERC20 allowance, and that allowances are correctly updated.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626RedeemUsingApproval {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev         // RedemptionProxy will be automatically created
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626RedeemUsingApproval is
    CryticERC4626PropertyBase,
    CryticERC4626VaultProxy
{

    /* ================================================================

                    APPROVED REDEMPTION PROPERTIES

       Description: Properties verifying approved redeem/withdraw work
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Redeem Via Approval Proxy Works Correctly
    /// @notice Third parties can redeem shares with proper share token approval
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After approving shares to a proxy and calling `redeemOnBehalf()`,
    /// @dev the redemption succeeds and the proxy's allowance is reduced to zero
    /// @dev This ensures the ERC4626 standard's requirement that redeem() must support
    /// @dev ERC20 approval for third-party redemptions, enabling composability with other contracts.
    /// @custom:property-id ERC4626-APPROVAL-001
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

    /// @title Withdraw Via Approval Proxy Works Correctly
    /// @notice Third parties can withdraw assets with proper share token approval
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: After approving shares to a proxy and calling `withdrawOnBehalf()`,
    /// @dev the withdrawal succeeds and the proxy's allowance is reduced by shares consumed
    /// @dev This ensures the ERC4626 standard's requirement that withdraw() must support
    /// @dev ERC20 approval for third-party withdrawals, enabling flexible redemption strategies.
    /// @custom:property-id ERC4626-APPROVAL-002
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


    /* ================================================================

                    APPROVAL REQUIREMENT PROPERTIES

       Description: Properties verifying approval is required
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Withdraw Requires Token Approval
    /// @notice Third parties cannot withdraw without sufficient share approval
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: A proxy with insufficient share allowance cannot call `withdraw()`
    /// @dev to burn more shares than approved, or the operation reverts
    /// @dev This critical security property prevents unauthorized withdrawals and ensures
    /// @dev the ERC20 approval mechanism is properly enforced for vault share tokens.
    /// @custom:property-id ERC4626-APPROVAL-003
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

    /// @title Redeem Requires Token Approval
    /// @notice Third parties cannot redeem without sufficient share approval
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: A proxy with insufficient share allowance cannot call `redeem()`
    /// @dev to burn more shares than approved, or the operation reverts
    /// @dev This critical security property prevents unauthorized redemptions and ensures
    /// @dev users maintain full control over their vault shares through the ERC20 approval system.
    /// @custom:property-id ERC4626-APPROVAL-004
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
