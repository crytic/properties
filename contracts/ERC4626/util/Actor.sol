// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "../../util/IERC4626.sol";
import {TestERC20Token} from "../util/TestERC20Token.sol";
import {PropertiesAsserts} from "../../util/PropertiesAsserts.sol";

/// @notice This contract has two purposes:
///  1. Act as a proxy for performing vault deposits/withdraws (since we don't have vm.prank)
///  2. Keep track of how much the account has deposited/withdrawn & raise an error if the account can withdraw/redeem more than it deposited/minted.
/// @dev It's important that other property tests never send tokens/shares to the Actor contract address, or else the accounting will break. This restriction is enforced in restrictAddressToThirdParties()
///      If support is added for "harvesting" a vault during property tests, the accounting logic here needs to be updated to reflect cases where an actor can withdraw more than they deposited.
contract Actor is PropertiesAsserts {
    TestERC20Token token;
    IERC4626 vault;

    uint256 tokensDeposited; //tracks how many aggregate tokens this actor has deposited on its own behalf
    uint256 sharesMinted; //tracks how many aggregate shares this actor has minted on its own behalf

    constructor(IERC4626 _vault) {
        vault = _vault;
        token = TestERC20Token(address(_vault.asset()));
    }

    function accountForOpenedPosition(
        uint256 _tokensDeposited,
        uint256 _sharesMinted
    ) internal {
        tokensDeposited += _tokensDeposited;
        sharesMinted += _sharesMinted;
    }

    function accountForClosedPosition(
        uint256 _tokensReceived,
        uint256 _sharesBurned
    ) internal {
        assertLte(
            _sharesBurned,
            sharesMinted,
            "Actor has burned more shares than they ever minted. Implies a rounding or accounting error"
        );
        assertLte(
            _tokensReceived,
            tokensDeposited,
            "Actor has withdrawn more tokens than they ever deposited. Implies a rounding or accounting error"
        );
        tokensDeposited -= _tokensReceived;
        sharesMinted -= _sharesBurned;
    }

    function fund(uint256 amount) public {
        token.mint(address(this), amount);
    }

    function approveFunds() public {
        token.approve(address(vault), type(uint256).max);
    }

    function depositFunds(
        uint256 assets
    ) public returns (uint256 _sharesMinted) {
        _sharesMinted = vault.deposit(assets, address(this));
        accountForOpenedPosition(assets, _sharesMinted);
    }

    function mintShares(
        uint256 shares
    ) public returns (uint256 _tokensDeposited) {
        _tokensDeposited = vault.mint(shares, address(this));
        accountForOpenedPosition(_tokensDeposited, shares);
    }

    function withdrawTokens(
        uint256 assets
    ) public returns (uint256 _sharesBurned) {
        _sharesBurned = vault.withdraw(assets, address(this), address(this));
        accountForClosedPosition(assets, _sharesBurned);
    }

    function redeemShares(
        uint256 shares
    ) public returns (uint256 _tokensWithdrawn) {
        _tokensWithdrawn = vault.redeem(shares, address(this), address(this));
        accountForClosedPosition(_tokensWithdrawn, shares);
    }

    function depositFundsOnBehalf(
        uint256 assets,
        address receiver
    ) public returns (uint256 _sharesMinted) {
        _sharesMinted = vault.deposit(assets, receiver);
    }

    function mintSharesOnBehalf(
        uint256 shares,
        address receiver
    ) public returns (uint256 _tokensDeposited) {
        _tokensDeposited = vault.mint(shares, receiver);
    }

    function withdrawTokensOnBehalf(
        uint256 assets,
        address receiver
    ) public returns (uint256 _sharesBurned) {
        _sharesBurned = vault.withdraw(assets, receiver, address(this));
        accountForClosedPosition(assets, _sharesBurned);
    }

    function redeemSharesOnBehalf(
        uint256 shares,
        address receiver
    ) public returns (uint256 _tokensWithdrawn) {
        _tokensWithdrawn = vault.redeem(shares, receiver, address(this));
        accountForClosedPosition(_tokensWithdrawn, shares);
    }
}
