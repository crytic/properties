// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Developers may optionally implement these interfaces on their Vault contract to increase coverage/enable rounding tests.
interface CryticIERC4626Internal {
    /// @notice Called by the fuzzer. The vault implementation should use TestERC20Token.mint() to credit itself with the amount of profit.
    function recognizeProfit(uint256 profit) external;

    /// @notice Called by the fuzzer. The vault implementation should use TestERC20Token.burn()/.transfer() to account for the amount of loss.
    function recognizeLoss(uint256 loss) external;
}
