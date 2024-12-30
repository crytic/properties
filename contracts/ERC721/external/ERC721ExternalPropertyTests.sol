// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {CryticERC721ExternalTestBase} from "./util/ERC721ExternalTestBase.sol";
import {CryticERC721ExternalBasicProperties} from "./properties/ERC721ExternalBasicProperties.sol";
import {CryticERC721ExternalBurnableProperties} from "./properties/ERC721ExternalBurnableProperties.sol";
import {CryticERC721ExternalMintableProperties} from "./properties/ERC721ExternalMintableProperties.sol";

/// @notice Aggregator contract for various ERC721 property tests. Inherit from this & echidna will test all properties at the same time.
abstract contract CryticERC721ExternalPropertyTests is CryticERC721ExternalBasicProperties, CryticERC721ExternalMintableProperties, CryticERC721ExternalBurnableProperties  {
} 
