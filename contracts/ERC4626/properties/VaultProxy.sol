// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {CryticERC4626PropertyBase} from "../util/ERC4626PropertyTestBase.sol";
import {CryticIERC4626Internal} from "../util/IERC4626Internal.sol";

contract CryticERC4626VaultProxy is CryticERC4626PropertyBase {
    function recognizeProfitProxy(uint256 profit) public {
        require(supportsInternalTestingIface);
        require(vault.totalSupply() > 0);
        CryticIERC4626Internal(address(vault)).recognizeProfit(profit);
    }

    function recognizeLossProxy(uint256 loss) public {
        require(supportsInternalTestingIface);
        require(vault.totalSupply() > 0);
        CryticIERC4626Internal(address(vault)).recognizeLoss(loss);
    }

    /// @dev intended to be used when property violations are being shrunk
    function depositForSelfSimple(uint256 assets) public {
        asset.mint(address(this), assets);
        asset.approve(address(vault), assets);
        vault.deposit(assets, address(this));
    }

    function redeemForSelfSimple(uint256 shares) public {
        shares = clampLte(shares, vault.balanceOf(address(this)));
        vault.redeem(shares, address(this), address(this));
    }

    // consider removing/refactoring the following since they're so unlikely to be useful during testing
    function deposit(uint256 assets, uint256 receiverId) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        vault.deposit(assets, receiver);
    }

    function withdraw(
        uint256 assets,
        uint256 ownerId,
        uint256 receiverId
    ) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        address owner = restrictAddressToThirdParties(ownerId);
        vault.withdraw(assets, receiver, owner);
    }

    function mint(uint256 shares, uint256 receiverId) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        vault.mint(shares, receiver);
    }

    function redeem(
        uint256 shares,
        uint256 ownerId,
        uint256 receiverId
    ) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        address owner = restrictAddressToThirdParties(ownerId);
        vault.redeem(shares, receiver, owner);
    }

    function mintAsset(uint256 assets, uint256 receiverId) public {
        address receiver = restrictAddressToThirdParties(receiverId);
        asset.mint(receiver, assets);
    }
}
