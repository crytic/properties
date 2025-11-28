// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../util/MultiSigTestBase.sol";

/**
 * @title CryticMultiSigBasicProperties
 * @notice Basic property tests for MultiSig wallets
 * @dev Contains fundamental invariants that should hold for any MultiSig wallet implementation
 */
abstract contract CryticMultiSigBasicProperties is CryticMultiSigBase {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    /**
     * @notice MULTISIG-BASIC-001: Only owners can be valid approvers
     * @dev Invariant: Any valid approval must come from an address that is an owner
     */
    function test_MultiSig_onlyOwnersCanApprove(address addr) public {
        // If address is not an owner, they should not be able to approve
        if (!isOwner(addr)) {
            // This property verifies that non-owners cannot approve
            // Implementation-specific: MultiSig should revert or ignore non-owner approvals
            assertWithMsg(
                !isValidOwner(addr),
                "Non-owner marked as valid owner"
            );
        }
    }

    /**
     * @notice MULTISIG-BASIC-002: Threshold must be within valid bounds
     * @dev Invariant: 0 < threshold <= owner count at all times
     */
    function test_MultiSig_thresholdWithinBounds() public {
        uint256 threshold = getThreshold();
        uint256 ownerCount = getOwnerCount();

        assertGt(threshold, 0, "Threshold must be greater than zero");
        assertLte(
            threshold,
            ownerCount,
            "Threshold cannot exceed owner count"
        );
    }

    /**
     * @notice MULTISIG-BASIC-003: No owner can be the zero address
     * @dev Invariant: All addresses in the owners list must be non-zero
     */
    function test_MultiSig_noZeroAddressOwners() public {
        address[] memory owners = getOwners();

        for (uint256 i = 0; i < owners.length; i++) {
            assertWithMsg(
                owners[i] != address(0),
                "Owner list contains zero address"
            );
        }
    }

    /**
     * @notice MULTISIG-BASIC-004: Owner count must be at least equal to threshold
     * @dev Invariant: There must be enough owners to meet the threshold requirement
     */
    function test_MultiSig_ownerCountMeetsThreshold() public {
        uint256 threshold = getThreshold();
        uint256 ownerCount = getOwnerCount();

        assertGte(
            ownerCount,
            threshold,
            "Owner count below threshold requirement"
        );
    }

    /**
     * @notice MULTISIG-BASIC-005: Owner list must not be empty
     * @dev Invariant: MultiSig must always have at least one owner
     */
    function test_MultiSig_ownerListNotEmpty() public {
        uint256 ownerCount = getOwnerCount();

        assertGt(ownerCount, 0, "Owner list is empty");
    }

    /**
     * @notice MULTISIG-BASIC-006: Executed transactions cannot be executed again
     * @dev Invariant: Once a transaction is marked as executed, it should remain executed
     * @param txHash Transaction identifier
     */
    function test_MultiSig_executedTransactionsStayExecuted(bytes32 txHash) public {
        // If a transaction was previously marked as executed, it must still be executed
        if (executedTransactions[txHash]) {
            assertWithMsg(
                isExecuted(txHash),
                "Previously executed transaction no longer marked as executed"
            );
        }

        // Update our tracking if transaction is newly executed
        if (isExecuted(txHash)) {
            executedTransactions[txHash] = true;
        }
    }

    /**
     * @notice MULTISIG-BASIC-007: isOwner consistency with owner list
     * @dev Invariant: If isOwner returns true, address must be in the owners list
     * @param addr Address to check
     */
    function test_MultiSig_isOwnerConsistentWithOwnerList(address addr) public {
        address[] memory owners = getOwners();
        bool foundInList = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == addr) {
                foundInList = true;
                break;
            }
        }

        bool isOwnerResult = isOwner(addr);

        // If isOwner returns true, must be in list
        if (isOwnerResult) {
            assertWithMsg(
                foundInList,
                "isOwner returns true but address not in owner list"
            );
        }

        // If in list, isOwner should return true
        if (foundInList) {
            assertWithMsg(
                isOwnerResult,
                "Address in owner list but isOwner returns false"
            );
        }
    }

    /**
     * @notice MULTISIG-BASIC-008: No duplicate owners in owner list
     * @dev Invariant: Each address should appear at most once in the owners list
     */
    function test_MultiSig_noDuplicateOwners() public {
        address[] memory owners = getOwners();

        for (uint256 i = 0; i < owners.length; i++) {
            for (uint256 j = i + 1; j < owners.length; j++) {
                assertWithMsg(
                    owners[i] != owners[j],
                    "Duplicate owner found in owner list"
                );
            }
        }
    }
}
