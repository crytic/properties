// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IMultiSigMock
 * @notice Interface for MultiSig wallet implementations used in external testing
 * @dev This interface defines the minimum required functions for property testing.
 *      MultiSig implementations should implement this interface for external mode testing.
 */
interface IMultiSigMock {
    ////////////////////////////////////////
    // Core MultiSig Functions

    /**
     * @notice Get the list of wallet owners
     * @return Array of owner addresses
     */
    function getOwners() external view returns (address[] memory);

    /**
     * @notice Get the current threshold (number of approvals required)
     * @return Current threshold value
     */
    function getThreshold() external view returns (uint256);

    /**
     * @notice Get the current nonce
     * @return Current nonce value
     */
    function getNonce() external view returns (uint256);

    /**
     * @notice Check if an address is an owner
     * @param owner Address to check
     * @return True if address is an owner
     */
    function isOwner(address owner) external view returns (bool);

    /**
     * @notice Get the number of approvals for a transaction
     * @param txHash Transaction hash or ID
     * @return Number of approvals
     */
    function getApprovalCount(bytes32 txHash) external view returns (uint256);

    /**
     * @notice Check if a transaction has been executed
     * @param txHash Transaction hash or ID
     * @return True if transaction has been executed
     */
    function isExecuted(bytes32 txHash) external view returns (bool);

    /**
     * @notice Check if an owner has approved a transaction
     * @param txHash Transaction hash or ID
     * @param owner Owner address
     * @return True if owner has approved
     */
    function hasApproved(bytes32 txHash, address owner) external view returns (bool);

    ////////////////////////////////////////
    // Transaction Management Functions

    /**
     * @notice Submit a new transaction proposal
     * @param to Destination address
     * @param value ETH value to send
     * @param data Transaction data
     * @return txHash Transaction identifier
     */
    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bytes32 txHash);

    /**
     * @notice Approve a submitted transaction
     * @param txHash Transaction identifier
     */
    function approveTransaction(bytes32 txHash) external;

    /**
     * @notice Execute a transaction that has enough approvals
     * @param txHash Transaction identifier
     */
    function executeTransaction(bytes32 txHash) external;

    /**
     * @notice Revoke a previous approval
     * @param txHash Transaction identifier
     */
    function revokeApproval(bytes32 txHash) external;

    ////////////////////////////////////////
    // Configuration Functions

    /**
     * @notice Add a new owner
     * @param owner Address to add as owner
     */
    function addOwner(address owner) external;

    /**
     * @notice Remove an existing owner
     * @param owner Address to remove from owners
     */
    function removeOwner(address owner) external;

    /**
     * @notice Change the threshold
     * @param newThreshold New threshold value
     */
    function changeThreshold(uint256 newThreshold) external;

    ////////////////////////////////////////
    // Property Testing State Functions

    /**
     * @notice Get initial threshold (for property testing)
     * @return Initial threshold value at deployment
     */
    function initialThreshold() external view returns (uint256);

    /**
     * @notice Get initial nonce (for property testing)
     * @return Initial nonce value at deployment
     */
    function initialNonce() external view returns (uint256);

    /**
     * @notice Get initial owner count (for property testing)
     * @return Initial number of owners at deployment
     */
    function initialOwnerCount() external view returns (uint256);

    ////////////////////////////////////////
    // Events

    event TransactionSubmitted(bytes32 indexed txHash, address indexed submitter);
    event TransactionApproved(bytes32 indexed txHash, address indexed approver);
    event TransactionExecuted(bytes32 indexed txHash);
    event ApprovalRevoked(bytes32 indexed txHash, address indexed owner);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 newThreshold);
}
