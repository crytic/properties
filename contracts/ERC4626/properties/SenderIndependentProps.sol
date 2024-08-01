// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";

contract CryticERC4626SenderIndependent is CryticERC4626PropertyBase {
    // todo: these properties may have issues in vaults that have super weird redemption curves.
    // If that happens, use a proxy contract to compare results instead of msg.sender's state

    /// @notice verify `maxDeposit()` assumes the receiver/sender has infinite assets
    function verify_maxDepositIgnoresSenderAssets(uint256 tokens) public {
        address receiver = address(this);
        uint256 maxDepositBefore = vault.maxDeposit(receiver);
        asset.mint(receiver, tokens);
        uint256 maxDepositAfter = vault.maxDeposit(receiver);
        assertEq(
            maxDepositBefore,
            maxDepositAfter,
            "maxDeposit must assume the agent has infinite assets"
        );
    }

    /// @notice verify `maxMint()` assumes the receiver/sender has infinite assets
    function verify_maxMintIgnoresSenderAssets(uint256 tokens) public {
        address receiver = address(this);
        uint256 maxMintBefore = vault.maxMint(receiver);
        asset.mint(receiver, tokens);
        uint256 maxMintAfter = vault.maxMint(receiver);
        assertEq(
            maxMintBefore,
            maxMintAfter,
            "maxMint must assume the agent has infinite assets"
        );
    }

    /// @notice verify `previewMint()` does not account for msg.sender asset balance
    function verify_previewMintIgnoresSender(
        uint256 tokens,
        uint256 shares
    ) public {
        address receiver = address(this);
        uint256 assetsExpectedBefore = vault.previewMint(shares);
        prepareAddressForDeposit(receiver, tokens);

        uint256 assetsExpectedAfter = vault.previewMint(shares);
        assertEq(
            assetsExpectedBefore,
            assetsExpectedAfter,
            "previewMint must not be dependent on msg.sender"
        );
    }

    /// @notice verify `previewDeposit()` does not account for msg.sender asset balance
    function verify_previewDepositIgnoresSender(uint256 tokens) public {
        address receiver = address(this);
        uint256 sharesExpectedBefore = vault.previewDeposit(tokens);
        prepareAddressForDeposit(receiver, tokens);

        uint256 sharesExpectedAfter = vault.previewDeposit(tokens);
        assertEq(
            sharesExpectedBefore,
            sharesExpectedAfter,
            "previewDeposit must not be dependent on msg.sender"
        );
    }

    /// @notice verify `previewWithdraw()` does not account for msg.sender asset balance
    function verify_previewWithdrawIgnoresSender(uint256 tokens) public {
        address receiver = address(this);
        uint256 sharesExpectedBefore = vault.previewWithdraw(tokens);
        prepareAddressForDeposit(receiver, tokens);

        vault.deposit(tokens, receiver);

        uint256 sharesExpectedAfter = vault.previewWithdraw(tokens);
        assertEq(
            sharesExpectedBefore,
            sharesExpectedAfter,
            "previewWithdraw must not be dependent on msg.sender"
        );

        // keep this property relatively stateless
        vault.redeem(vault.balanceOf(receiver), receiver, receiver);
    }

    /// @notice verify `previewRedeem()` does not account for msg.sender asset balance
    function verify_previewRedeemIgnoresSender(uint256 shares) public {
        address receiver = address(this);
        uint256 tokensExpectedBefore = vault.previewRedeem(shares);

        uint256 assetsToDeposit = vault.previewMint(shares);
        prepareAddressForDeposit(receiver, assetsToDeposit);

        vault.deposit(assetsToDeposit, receiver);

        uint256 tokensExpectedAfter = vault.previewRedeem(shares);
        assertEq(
            tokensExpectedBefore,
            tokensExpectedAfter,
            "previewRedeem must not be dependent on msg.sender"
        );

        // keep this property relatively stateless
        vault.redeem(vault.balanceOf(receiver), receiver, receiver);
    }
}
