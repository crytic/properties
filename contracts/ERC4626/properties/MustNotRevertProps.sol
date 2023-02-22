pragma solidity ^0.8.0;

import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticERC4626VaultProxy} from "./VaultProxy.sol";
contract CryticERC4626MustNotRevert is CryticERC4626PropertyBase, CryticERC4626VaultProxy {

    /// @notice Validates the following properties:
    /// - vault.asset() must not revert
    function verify_assetMustNotRevert() public {
        try vault.asset() {
            return;
        } catch {
            assertWithMsg(false, "vault.asset() must not revert");
        }
    }

    /// @notice Validates the following properties:
    /// - vault.totalAssets() must not revert
    function verify_totalAssetsMustNotRevert() public {
        try vault.totalAssets() {
            return;
        } catch {
            assertWithMsg(false, "vault.totalAssets() must not revert");
        }
    }

    /// @notice Validates the following properties:
    /// - vault.convertToAssets() must not revert for reasonable values
    function verify_convertToAssetsMustNotRevert(uint256 shares) public {
        // arbitrarily define "reasonable values" to be 10**(token.decimals+20)
        uint256 reasonably_largest_value = 10**(vault.decimals()+20);

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

    /// @notice Validates the following properties:
    /// - vault.convertToShares() must not revert for reasonable values
    function verify_convertToSharesMustNotRevert(uint256 tokens) public {
        // arbitrarily define "reasonable values" to be 10**(token.decimals+20)
        uint256 reasonably_largest_value = 10**(asset.decimals()+20);

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

    function verify_maxDepositMustNotRevert(address owner) public {
        try vault.maxDeposit(owner) {
            return;
        } catch {
            assertWithMsg(false, "vault.maxDeposit() must not revert");
        }
    }

    function verify_maxMintMustNotRevert(address owner) public {
        try vault.maxMint(owner) {
            return;
        } catch {
            assertWithMsg(false, "vault.maxMint() must not revert");
        }
    }

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
}
