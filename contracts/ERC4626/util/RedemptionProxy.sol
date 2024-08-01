// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "../../util/IERC4626.sol";

contract RedemptionProxy {
    IERC4626 vault;

    constructor(IERC4626 _vault) {
        vault = _vault;
    }

    function redeemOnBehalf(
        uint256 shares,
        address receiver,
        address owner
    ) public returns (uint256 tokensWithdrawn) {
        tokensWithdrawn = vault.redeem(shares, receiver, owner);
    }

    function withdrawOnBehalf(
        uint256 tokens,
        address receiver,
        address owner
    ) public returns (uint256 sharesRedeemed) {
        sharesRedeemed = vault.withdraw(tokens, receiver, owner);
    }
}
