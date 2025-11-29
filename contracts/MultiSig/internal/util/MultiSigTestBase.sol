// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesAsserts.sol";

/**
 * @title CryticMultiSigBase
 * @notice Base contract for MultiSig property testing (internal mode)
 * @dev This abstract contract should be inherited by the MultiSig implementation
 *      and provides utilities and state tracking for property-based testing.
 *
 *      The MultiSig implementation must provide the abstract functions defined here.
 */
abstract contract CryticMultiSigBase is
    PropertiesAsserts,
    PropertiesConstants
{
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
    // Abstract functions that MultiSig implementation must provide

    /**
     * @notice Get the list of wallet owners
     * @return Array of owner addresses
     */
    function getOwners() public view virtual returns (address[] memory);

    /**
     * @notice Get the current threshold (number of approvals required)
     * @return Current threshold value
     */
    function getThreshold() public view virtual returns (uint256);

    /**
     * @notice Get the current nonce
     * @return Current nonce value
     */
    function getNonce() public view virtual returns (uint256);

    /**
     * @notice Check if an address is an owner
     * @param owner Address to check
     * @return True if address is an owner
     */
    function isOwner(address owner) public view virtual returns (bool);

    /**
     * @notice Get the number of approvals for a transaction
     * @param txHash Transaction hash or ID
     * @return Number of approvals
     */
    function getApprovalCount(bytes32 txHash) public view virtual returns (uint256);

    /**
     * @notice Check if a transaction has been executed
     * @param txHash Transaction hash or ID
     * @return True if transaction has been executed
     */
    function isExecuted(bytes32 txHash) public view virtual returns (bool);

    /**
     * @notice Check if an owner has approved a transaction
     * @param txHash Transaction hash or ID
     * @param owner Owner address
     * @return True if owner has approved
     */
    function hasApproved(bytes32 txHash, address owner) public view virtual returns (bool);

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
