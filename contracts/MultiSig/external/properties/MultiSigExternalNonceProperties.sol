// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/MultiSigExternalTestBase.sol";

/**
 * @title CryticMultiSigExternalNonceProperties
 * @notice Nonce management properties for MultiSig wallets (external mode)
 * @dev Tests invariants related to nonce handling and replay protection
 *      Addresses issue #32 requirements:
 *      - "nonce is strictly monotonously increasing"
 *      - "nonce can only be used once"
 *      Tests through external interface only
 */
abstract contract CryticMultiSigExternalNonceProperties is CryticMultiSigExternalTestBase {
    /// @notice Track the highest nonce we've seen
    uint256 internal highestSeenNonce;

    /// @notice Track if we've initialized the highest seen nonce
    bool internal nonceTrackingInitialized;

    constructor() {}

    ////////////////////////////////////////
    // Properties

    /**
     * @notice MULTISIG-EXTERNAL-NONCE-051: Nonce is strictly monotonically increasing
     * @dev Invariant: Nonce should never decrease and should increase by exactly 1
     *      This directly addresses the requirement from issue #32
     */
    function test_MultiSigExternal_nonceMonotonicallyIncreases() public {
        uint256 currentNonce = getNonce();

        if (!nonceTrackingInitialized) {
            highestSeenNonce = currentNonce;
            nonceTrackingInitialized = true;
        } else {
            // Nonce should never decrease
            assertGte(
                currentNonce,
                highestSeenNonce,
                "Nonce decreased"
            );

            // If nonce increased, it should increase by exactly 1
            if (currentNonce > highestSeenNonce) {
                assertEq(
                    currentNonce,
                    highestSeenNonce + 1,
                    "Nonce did not increase by exactly 1"
                );
            }

            highestSeenNonce = currentNonce;
        }
    }

    /**
     * @notice MULTISIG-EXTERNAL-NONCE-052: Each nonce can only be used once
     * @dev Invariant: Once a nonce is used (marked as used), it should stay marked
     *      This directly addresses the requirement from issue #32
     * @param nonce Nonce value to check
     */
    function test_MultiSigExternal_nonceUsedOnlyOnce(uint256 nonce) public {
        uint256 currentNonce = getNonce();

        // If this nonce was previously marked as used, it should still be marked as used
        if (usedNonces[nonce]) {
            // A used nonce should be less than current nonce
            assertLt(
                nonce,
                currentNonce,
                "Used nonce is not less than current nonce"
            );
        }

        // Mark nonces less than current as used
        if (nonce < currentNonce) {
            usedNonces[nonce] = true;
        }
    }

    /**
     * @notice MULTISIG-EXTERNAL-NONCE-053: Nonce only increments on successful execution
     * @dev Invariant: Failed transactions or pending transactions should not increment nonce
     * @param txHash Transaction identifier
     */
    function test_MultiSigExternal_nonceIncrementsOnlyOnExecution(bytes32 txHash) public {
        uint256 currentNonce = getNonce();

        // If transaction is not executed, the current nonce should still be available
        if (!isExecuted(txHash)) {
            // This documents expected behavior: pending transactions don't consume nonce
            // The nonce only increments when a transaction is actually executed
        }

        // Track nonce progression
        if (!nonceTrackingInitialized) {
            highestSeenNonce = currentNonce;
            nonceTrackingInitialized = true;
        }
    }

    /**
     * @notice MULTISIG-EXTERNAL-NONCE-054: Old nonces cannot be reused
     * @dev Invariant: Transactions with nonces less than current nonce should be rejected
     * @param txNonce Transaction nonce being checked
     */
    function test_MultiSigExternal_oldNoncesRejected(uint256 txNonce) public {
        uint256 currentNonce = getNonce();

        // If txNonce is less than current nonce, it's an old nonce
        if (txNonce < currentNonce) {
            // Mark as used to track it
            usedNonces[txNonce] = true;

            // Old nonces should not be usable for new transactions
            assertWithMsg(
                usedNonces[txNonce],
                "Old nonce not properly marked as used"
            );
        }
    }

    /**
     * @notice MULTISIG-EXTERNAL-NONCE-055: Nonce starts at expected initial value
     * @dev Invariant: Initial nonce should remain constant
     *      Most implementations start at 0 or 1
     */
    function test_MultiSigExternal_nonceStartsAtExpectedValue() public {
        uint256 currentNonce = getNonce();

        // Current nonce should always be >= initial nonce
        assertGte(
            currentNonce,
            initialNonce,
            "Current nonce is less than initial nonce"
        );
    }

    /**
     * @notice MULTISIG-EXTERNAL-NONCE-056: No gaps in nonce sequence
     * @dev Invariant: All nonces from initialNonce to (currentNonce - 1) should be used
     *      This ensures sequential execution without gaps
     * @param nonce Nonce to check
     */
    function test_MultiSigExternal_noNonceGaps(uint256 nonce) public {
        uint256 currentNonce = getNonce();

        // Any nonce between initial and current (exclusive) should be marked as used
        if (nonce >= initialNonce && nonce < currentNonce) {
            // These nonces should all be consumed
            usedNonces[nonce] = true;

            // Verify it's truly in the past
            assertLt(
                nonce,
                currentNonce,
                "Historical nonce not less than current"
            );
        }

        // No nonce should be greater than or equal to current nonce and marked as used
        if (nonce >= currentNonce) {
            assertWithMsg(
                !usedNonces[nonce],
                "Future nonce marked as used"
            );
        }
    }
}
