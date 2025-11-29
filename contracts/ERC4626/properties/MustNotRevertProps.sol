// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticERC4626VaultProxy} from "./VaultProxy.sol";

/**
 * @title ERC4626 Must Not Revert Properties
 * @author Crytic (Trail of Bits)
 * @notice Properties ensuring ERC4626 view functions are always available
 * @dev Testing Mode: INTERNAL (test harness inherits from vault and properties)
 * @dev This contract contains 9 properties that verify vault view functions never revert
 * @dev under reasonable conditions. These functions must remain callable to ensure
 * @dev integrations can always query vault state without unexpected failures.
 * @dev
 * @dev Usage Example:
 * @dev ```solidity
 * @dev contract TestHarness is MyERC4626Vault, CryticERC4626MustNotRevert {
 * @dev     constructor() {
 * @dev         // Initialize vault with underlying asset
 * @dev     }
 * @dev }
 * @dev ```
 */
contract CryticERC4626MustNotRevert is
    CryticERC4626PropertyBase,
    CryticERC4626VaultProxy
{

    /* ================================================================

                    BASIC INFO AVAILABILITY PROPERTIES

       Description: Properties verifying core information functions
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Asset Function Must Not Revert
    /// @notice The asset() function should always be callable
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.asset()` must not revert
    /// @dev The asset() function returns the underlying ERC20 token address. This is fundamental
    /// @dev vault metadata that must always be accessible for integrations to function properly.
    /// @custom:property-id ERC4626-AVAILABILITY-001
    function verify_assetMustNotRevert() public {
        try vault.asset() {
            return;
        } catch {
            assertWithMsg(false, "vault.asset() must not revert");
        }
    }

    /// @title Total Assets Function Must Not Revert
    /// @notice The totalAssets() function should always be callable
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.totalAssets()` must not revert
    /// @dev The totalAssets() function returns the total amount of underlying assets held by the vault.
    /// @dev This critical information must always be available for calculating share prices and redemptions.
    /// @custom:property-id ERC4626-AVAILABILITY-002
    function verify_totalAssetsMustNotRevert() public {
        try vault.totalAssets() {
            return;
        } catch {
            assertWithMsg(false, "vault.totalAssets() must not revert");
        }
    }


    /* ================================================================

                    CONVERSION AVAILABILITY PROPERTIES

       Description: Properties verifying conversion functions
       Testing Mode: INTERNAL
       Property Count: 2

       ================================================================ */

    /// @title Convert To Assets Must Not Revert
    /// @notice The convertToAssets() function should not revert for reasonable values
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.convertToAssets(shares)` must not revert for reasonable share amounts
    /// @dev Reasonable values are defined as shares <= totalSupply and < 10**(decimals+20)
    /// @dev This conversion is essential for users to understand the asset value of their shares
    /// @dev and must be available for UI integrations and contract interactions.
    /// @custom:property-id ERC4626-AVAILABILITY-003
    function verify_convertToAssetsMustNotRevert(uint256 shares) public {
        // arbitrarily define "reasonable values" to be 10**(token.decimals+20)
        uint256 reasonably_largest_value = 10 ** (vault.decimals() + 20);

        // prevent scenarios where there is enough totalSupply to trigger overflows
        require(vault.totalSupply() <= reasonably_largest_value);
        shares = clampLte(shares, reasonably_largest_value);

        // exclude the possibility of idiosyncratic reverts. Might have to add more in future.
        shares = clampLte(shares, vault.totalSupply());

        emit LogUint256("totalSupply", vault.totalSupply());
        emit LogUint256("totalAssets", vault.totalAssets());

        try vault.convertToAssets(shares) {
            return;
        } catch {
            assertWithMsg(false, "vault.convertToAssets() must not revert");
        }
    }

    /// @title Convert To Shares Must Not Revert
    /// @notice The convertToShares() function should not revert for reasonable values
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.convertToShares(tokens)` must not revert for reasonable asset amounts
    /// @dev Reasonable values are defined as tokens <= asset.totalSupply and < 10**(asset.decimals+20)
    /// @dev This conversion is essential for users to preview how many shares they will receive
    /// @dev for a given asset amount before depositing.
    /// @custom:property-id ERC4626-AVAILABILITY-004
    function verify_convertToSharesMustNotRevert(uint256 tokens) public {
        // arbitrarily define "reasonable values" to be 10**(token.decimals+20)
        uint256 reasonably_largest_value = 10 ** (asset.decimals() + 20);

        // prevent scenarios where there is enough totalSupply to trigger overflows
        require(asset.totalSupply() <= reasonably_largest_value);

        // exclude the possibility of idiosyncratic reverts. Might have to add more in future.
        tokens = clampLte(tokens, asset.totalSupply());

        try vault.convertToShares(tokens) {
            return;
        } catch {
            assertWithMsg(false, "vault.convertToShares() must not revert");
        }
    }


    /* ================================================================

                    MAX OPERATION AVAILABILITY PROPERTIES

       Description: Properties verifying max limit query functions
       Testing Mode: INTERNAL
       Property Count: 4

       ================================================================ */

    /// @title Max Deposit Must Not Revert
    /// @notice The maxDeposit() function should always be callable
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.maxDeposit(owner)` must not revert
    /// @dev This function returns the maximum amount of assets that can be deposited for an owner.
    /// @dev UIs and integrations rely on this to validate user inputs before attempting deposits.
    /// @custom:property-id ERC4626-AVAILABILITY-005
    function verify_maxDepositMustNotRevert(address owner) public {
        try vault.maxDeposit(owner) {
            return;
        } catch {
            assertWithMsg(false, "vault.maxDeposit() must not revert");
        }
    }

    /// @title Max Mint Must Not Revert
    /// @notice The maxMint() function should always be callable
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.maxMint(owner)` must not revert
    /// @dev This function returns the maximum number of shares that can be minted for an owner.
    /// @dev UIs and integrations rely on this to validate user inputs before attempting mints.
    /// @custom:property-id ERC4626-AVAILABILITY-006
    function verify_maxMintMustNotRevert(address owner) public {
        try vault.maxMint(owner) {
            return;
        } catch {
            assertWithMsg(false, "vault.maxMint() must not revert");
        }
    }

    /// @title Max Redeem Must Not Revert
    /// @notice The maxRedeem() function should always be callable when valid
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.maxRedeem(owner)` must not revert when conversions are valid
    /// @dev This function returns the maximum number of shares that can be redeemed by an owner.
    /// @dev UIs rely on this to show users the maximum they can redeem. The function may only
    /// @dev revert if convertToAssets would overflow, which is tested first.
    /// @custom:property-id ERC4626-AVAILABILITY-007
    function verify_maxRedeemMustNotRevert(address owner) public {
        // if the following reverts from overflow, bail out.
        // additional criterion might be required in the future
        vault.convertToAssets(vault.balanceOf(owner));

        try vault.maxRedeem(owner) {
            return;
        } catch {
            assertWithMsg(false, "vault.maxRedeem() must not revert");
        }
    }

    /// @title Max Withdraw Must Not Revert
    /// @notice The maxWithdraw() function should always be callable when valid
    /// @dev Testing Mode: INTERNAL
    /// @dev Invariant: `vault.maxWithdraw(owner)` must not revert when conversions are valid
    /// @dev This function returns the maximum amount of assets that can be withdrawn by an owner.
    /// @dev UIs rely on this to show users the maximum they can withdraw. The function may only
    /// @dev revert if convertToAssets would overflow, which is tested first.
    /// @custom:property-id ERC4626-AVAILABILITY-008
    function verify_maxWithdrawMustNotRevert(address owner) public {
        // if the following reverts from overflow, bail out.
        // additional criterion might be required in the future
        vault.convertToAssets(vault.balanceOf(owner));

        try vault.maxWithdraw(owner) {
            return;
        } catch {
            assertWithMsg(false, "vault.maxWithdraw() must not revert");
        }
    }


    /* ================================================================

                    PREVIEW AVAILABILITY PROPERTIES

       Description: Properties verifying preview query functions
       Testing Mode: INTERNAL
       Property Count: 1

       ================================================================ */

    /// @title Preview Functions Available Through Proxy
    /// @notice Preview functions are indirectly tested through other properties
    /// @dev Testing Mode: INTERNAL
    /// @dev The vault proxy provides access to preview functions which are tested
    /// @dev in other property files (FunctionalAccountingProps, RoundingProps).
    /// @dev No additional direct availability tests are needed here.
    /// @custom:property-id ERC4626-AVAILABILITY-009
}
