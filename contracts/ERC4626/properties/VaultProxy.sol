// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticIERC4626Internal} from "../util/IERC4626Internal.sol";

/**
 * @title ERC4626 Vault Proxy
 * @author Crytic (Trail of Bits)
 * @notice Helper proxy functions for testing ERC4626 vaults with complex scenarios
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract provides utility functions to enable more complex fuzz testing scenarios
 * @dev for ERC4626 vaults, including profit/loss recognition, simplified operations for shrinking,
 * @dev and various vault operation wrappers. These are not properties themselves but support
 * @dev property testing by expanding the action space available to the fuzzer.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626VaultProxy {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev         // Proxy functions will be available for fuzzer
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626VaultProxy is CryticERC4626PropertyBase {

    /* ================================================================

                    PROFIT/LOSS SIMULATION PROXIES

       Description: Functions to simulate vault profit/loss scenarios
       Testing Mode: INTERNAL
       Purpose: Enable testing vault behavior under gains/losses

       ================================================================ */

    /// @title Recognize Profit Proxy
    /// @notice Simulates vault earning profit on deployed assets
    /// @dev Testing Mode: INTERNAL
    /// @dev This function allows the fuzzer to test vault behavior when underlying assets
    /// @dev increase in value (e.g., yield farming profits, interest earned). Requires
    /// @dev vault to implement the internal testing interface for profit recognition.
    /// @custom:property-id ERC4626-PROXY-001
    function recognizeProfitProxy(uint256 profit) public {
        require(supportsInternalTestingIface);
        require(vault.totalSupply() > 0);
        CryticIERC4626Internal(address(vault)).recognizeProfit(profit);
    }

    /// @title Recognize Loss Proxy
    /// @notice Simulates vault losing value on deployed assets
    /// @dev Testing Mode: INTERNAL
    /// @dev This function allows the fuzzer to test vault behavior when underlying assets
    /// @dev decrease in value (e.g., bad debt, impermanent loss). Requires vault to implement
    /// @dev the internal testing interface for loss recognition.
    /// @custom:property-id ERC4626-PROXY-002
    function recognizeLossProxy(uint256 loss) public {
        require(supportsInternalTestingIface);
        require(vault.totalSupply() > 0);
        CryticIERC4626Internal(address(vault)).recognizeLoss(loss);
    }


    /* ================================================================

                    SIMPLIFIED OPERATION PROXIES

       Description: Simplified deposit/redeem for counterexample shrinking
       Testing Mode: INTERNAL
       Purpose: Make counterexamples more readable

       ================================================================ */

    /// @title Deposit For Self Simple
    /// @notice Simplified deposit function for cleaner counterexamples
    /// @dev Testing Mode: INTERNAL
    /// @dev When a property fails, the fuzzer shrinks the counterexample to the minimal
    /// @dev reproduction. This simplified function makes the shrunk test case more readable
    /// @dev by combining mint, approve, and deposit into a single step.
    /// @custom:property-id ERC4626-PROXY-003
    function depositForSelfSimple(uint256 assets) public {
        asset.mint(address(this), assets);
        asset.approve(address(vault), assets);
        vault.deposit(assets, address(this));
    }

    /// @title Redeem For Self Simple
    /// @notice Simplified redeem function for cleaner counterexamples
    /// @dev Testing Mode: INTERNAL
    /// @dev When a property fails, this simplified function makes the shrunk counterexample
    /// @dev more readable by handling share balance clamping internally and reducing the
    /// @dev complexity of the failing test case.
    /// @custom:property-id ERC4626-PROXY-004
    function redeemForSelfSimple(uint256 shares) public {
        shares = clampLte(shares, vault.balanceOf(address(this)));
        vault.redeem(shares, address(this), address(this));
    }


    /* ================================================================

                    MULTI-PARTY OPERATION PROXIES

       Description: Wrappers for multi-party vault operations
       Testing Mode: INTERNAL
       Purpose: Enable fuzzer to test complex interaction patterns

       ================================================================ */

    /// @title Deposit Proxy
    /// @notice Deposit assets to a third-party receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Enables the fuzzer to explore scenarios where deposit sender and receiver differ,
    /// @dev which is important for testing delegation patterns and ensuring proper accounting
    /// @dev when shares are minted to addresses other than msg.sender.
    /// @custom:property-id ERC4626-PROXY-005
    function deposit(uint256 assets, uint256 receiverId) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        vault.deposit(assets, receiver);
    }

    /// @title Withdraw Proxy
    /// @notice Withdraw assets on behalf of owner to receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Enables the fuzzer to explore three-party withdraw scenarios (msg.sender, owner, receiver),
    /// @dev which tests approval mechanisms and ensures proper accounting across multiple addresses.
    /// @custom:property-id ERC4626-PROXY-006
    function withdraw(
        uint256 assets,
        uint256 ownerId,
        uint256 receiverId
    ) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        address owner = restrictAddressToThirdParties(ownerId);
        vault.withdraw(assets, receiver, owner);
    }

    /// @title Mint Proxy
    /// @notice Mint shares to a third-party receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Enables the fuzzer to explore scenarios where mint sender and receiver differ,
    /// @dev testing that shares are correctly allocated when minted to addresses other than
    /// @dev the asset provider (msg.sender).
    /// @custom:property-id ERC4626-PROXY-007
    function mint(uint256 shares, uint256 receiverId) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        vault.mint(shares, receiver);
    }

    /// @title Redeem Proxy
    /// @notice Redeem shares on behalf of owner for receiver
    /// @dev Testing Mode: INTERNAL
    /// @dev Enables the fuzzer to explore three-party redeem scenarios (msg.sender, owner, receiver),
    /// @dev which tests approval mechanisms and ensures proper share burning and asset distribution
    /// @dev across multiple addresses.
    /// @custom:property-id ERC4626-PROXY-008
    function redeem(
        uint256 shares,
        uint256 ownerId,
        uint256 receiverId
    ) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        address owner = restrictAddressToThirdParties(ownerId);
        vault.redeem(shares, receiver, owner);
    }


    /* ================================================================

                    ASSET MANIPULATION PROXIES

       Description: Functions to manipulate underlying asset state
       Testing Mode: INTERNAL
       Purpose: Enable fuzzer to test vault behavior with varying asset states

       ================================================================ */

    /// @title Mint Asset Proxy
    /// @notice Mint underlying assets to a third party
    /// @dev Testing Mode: INTERNAL
    /// @dev Enables the fuzzer to create diverse asset distribution scenarios, testing that
    /// @dev vault operations behave correctly regardless of how assets are distributed among users.
    /// @dev This is particularly useful for testing sender-independent properties.
    /// @custom:property-id ERC4626-PROXY-009
    function mintAsset(uint256 assets, uint256 receiverId) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        asset.mint(receiver, assets);
    }


    /* ================================================================

                    ADDITIONAL UTILITY PROXIES

       Description: Additional helper functions for complex scenarios
       Testing Mode: INTERNAL
       Purpose: Future expansion of testing capabilities

       ================================================================ */

    /// @dev Additional proxy functions can be added here to support testing of:
    /// @dev - Emergency withdrawal scenarios
    /// @dev - Fee collection mechanisms
    /// @dev - Strategy rebalancing operations
    /// @dev - Pause/unpause functionality
    /// @dev - Upgradability patterns
}
