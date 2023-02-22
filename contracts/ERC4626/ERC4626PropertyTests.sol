pragma solidity ^0.8.0;

import {TestERC20Token} from "./util/TestERC20Token.sol";
import {CryticERC4626RedeemUsingApproval} from "./properties/RedeemUsingApprovalProps.sol";
import {CryticERC4626SenderIndependent} from "./properties/SenderIndependentProps.sol";
import {CryticERC4626PropertyBase} from "./util/ERC4626PropertyTestBase.sol";
import {CryticERC4626MustNotRevert} from "./properties/MustNotRevertProps.sol";
import {CryticERC4626FunctionalAccounting} from "./properties/FunctionalAccountingProps.sol";
import {CryticERC4626Rounding} from "./properties/RoundingProps.sol";
import {CryticERC4626VaultProxy} from "./properties/VaultProxy.sol";
import {CryticERC4626SecurityProps} from "./properties/SecurityProps.sol";

/// @notice Aggregator contract for various 4626 property tests. Inherit from this & echidna will test all properties at the same time.
contract CryticERC4626PropertyTests is 
    CryticERC4626RedeemUsingApproval, 
    CryticERC4626MustNotRevert, 
    CryticERC4626SenderIndependent,
    CryticERC4626FunctionalAccounting,
    CryticERC4626Rounding, 
    CryticERC4626SecurityProps{
}