// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/MultiSigTestBase.sol";

/**
 * @title CryticMultiSigThresholdProperties
 * @notice Threshold validation properties for MultiSig wallets
 * @dev Tests invariants related to threshold requirements and execution conditions
 *      Addresses issue #32 requirement: "If votes < threshold, calls can't be executed"
 */
abstract contract CryticMultiSigThresholdProperties is CryticMultiSigBase {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    /**
     * @notice MULTISIG-THRESHOLD-001: Transactions with approvals below threshold cannot be executed
     * @dev Invariant: A transaction can only be executed if approvals >= threshold
     *      This directly addresses the requirement from issue #32
     * @param txHash Transaction identifier
     */
    function test_MultiSig_cannotExecuteBelowThreshold(bytes32 txHash) public {
        uint256 approvalCount = getApprovalCount(txHash);
        uint256 threshold = getThreshold();
        bool executed = isExecuted(txHash);

        // If a transaction is executed, it must have met the threshold
        if (executed) {
            assertGte(
                approvalCount,
                threshold,
                "Transaction executed with approvals below threshold"
            );
        }
    }

    /**
     * @notice MULTISIG-THRESHOLD-002: Approval count for non-executed transactions
     * @dev Invariant: If approvals < threshold, transaction should not be executed
     * @param txHash Transaction identifier
     */
    function test_MultiSig_insufficientApprovalsNotExecuted(bytes32 txHash) public {
        uint256 approvalCount = getApprovalCount(txHash);
        uint256 threshold = getThreshold();

        // If approvals are below threshold, transaction should not be executed
        if (approvalCount < threshold) {
            assertWithMsg(
                !isExecuted(txHash),
                "Transaction executed despite insufficient approvals"
            );
        }
    }

    /**
     * @notice MULTISIG-THRESHOLD-003: Threshold cannot be zero
     * @dev Invariant: Threshold must always be at least 1
     */
    function test_MultiSig_thresholdNeverZero() public {
        uint256 threshold = getThreshold();

        assertGt(threshold, 0, "Threshold is zero");
    }

    /**
     * @notice MULTISIG-THRESHOLD-004: Threshold cannot exceed owner count
     * @dev Invariant: It must be mathematically possible to reach the threshold
     */
    function test_MultiSig_thresholdNotAboveOwnerCount() public {
        uint256 threshold = getThreshold();
        uint256 ownerCount = getOwnerCount();

        assertLte(
            threshold,
            ownerCount,
            "Threshold exceeds number of owners"
        );
    }

    /**
     * @notice MULTISIG-THRESHOLD-005: Threshold changes maintain wallet operability
     * @dev Invariant: After any threshold change, it must still be <= owner count
     *      This ensures the wallet remains operational after configuration changes
     */
    function test_MultiSig_thresholdChangeMaintainsOperability() public {
        uint256 threshold = getThreshold();
        uint256 ownerCount = getOwnerCount();

        // Track threshold changes
        if (threshold != initialThreshold) {
            // Even after change, threshold must be valid
            assertGt(threshold, 0, "Threshold changed to zero");
            assertLte(
                threshold,
                ownerCount,
                "Threshold changed to value exceeding owner count"
            );
        }
    }

    /**
     * @notice MULTISIG-THRESHOLD-006: Approval count never exceeds owner count
     * @dev Invariant: Cannot have more approvals than there are owners
     *      This helps detect signature/approval counting errors
     * @param txHash Transaction identifier
     */
    function test_MultiSig_approvalCountWithinBounds(bytes32 txHash) public {
        uint256 approvalCount = getApprovalCount(txHash);
        uint256 ownerCount = getOwnerCount();

        assertLte(
            approvalCount,
            ownerCount,
            "Approval count exceeds total number of owners"
        );
    }
}
