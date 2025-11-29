// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMultiSigMock.sol";
import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesAsserts.sol";

/**
 * @title CryticMultiSigExternalTestBase
 * @notice Base contract for MultiSig property testing (external mode)
 * @dev This abstract contract provides utilities and state tracking for property-based testing
 *      of MultiSig implementations through their external interface.
 *
 *      External testing mode allows testing any MultiSig implementation without modification,
 *      treating it as a black box and interacting only through its public interface.
 */
abstract contract CryticMultiSigExternalTestBase is
    PropertiesAsserts,
    PropertiesConstants
{
    ////////////////////////////////////////
    // MultiSig contract reference

    /// @notice The MultiSig contract being tested
    IMultiSigMock internal wallet;

    ////////////////////////////////////////
    // State tracking for property testing

    /// @notice Initial threshold value after deployment
    uint256 internal initialThreshold;

    /// @notice Initial nonce value after deployment
    uint256 internal initialNonce;

    /// @notice Initial owner count after deployment
    uint256 internal initialOwnerCount;

    /// @notice Tracks whether a specific nonce has been used
    mapping(uint256 => bool) internal usedNonces;

    /// @notice Tracks transaction IDs that have been executed
    mapping(bytes32 => bool) internal executedTransactions;

    constructor() {}

    ////////////////////////////////////////
    // Wrapper functions for cleaner property code

    /**
     * @notice Get the list of wallet owners
     * @return Array of owner addresses
     */
    function getOwners() public view returns (address[] memory) {
        return wallet.getOwners();
    }

    /**
     * @notice Get the current threshold (number of approvals required)
     * @return Current threshold value
     */
    function getThreshold() public view returns (uint256) {
        return wallet.getThreshold();
    }

    /**
     * @notice Get the current nonce
     * @return Current nonce value
     */
    function getNonce() public view returns (uint256) {
        return wallet.getNonce();
    }

    /**
     * @notice Check if an address is an owner
     * @param owner Address to check
     * @return True if address is an owner
     */
    function isOwner(address owner) public view returns (bool) {
        return wallet.isOwner(owner);
    }

    /**
     * @notice Get the number of approvals for a transaction
     * @param txHash Transaction hash or ID
     * @return Number of approvals
     */
    function getApprovalCount(bytes32 txHash) public view returns (uint256) {
        return wallet.getApprovalCount(txHash);
    }

    /**
     * @notice Check if a transaction has been executed
     * @param txHash Transaction hash or ID
     * @return True if transaction has been executed
     */
    function isExecuted(bytes32 txHash) public view returns (bool) {
        return wallet.isExecuted(txHash);
    }

    /**
     * @notice Check if an owner has approved a transaction
     * @param txHash Transaction hash or ID
     * @param owner Owner address
     * @return True if owner has approved
     */
    function hasApproved(bytes32 txHash, address owner) public view returns (bool) {
        return wallet.hasApproved(txHash, owner);
    }

    ////////////////////////////////////////
    // Helper functions for properties

    /**
     * @notice Get the current owner count
     * @return Number of owners
     */
    function getOwnerCount() public view returns (uint256) {
        return getOwners().length;
    }

    /**
     * @notice Check if threshold is valid (0 < threshold <= owner count)
     * @return True if threshold is valid
     */
    function isValidThreshold() public view returns (bool) {
        uint256 threshold = getThreshold();
        uint256 ownerCount = getOwnerCount();
        return threshold > 0 && threshold <= ownerCount;
    }

    /**
     * @notice Check if an address is a valid owner (not zero address and is owner)
     * @param owner Address to check
     * @return True if valid owner
     */
    function isValidOwner(address owner) public view returns (bool) {
        return owner != address(0) && isOwner(owner);
    }
}
