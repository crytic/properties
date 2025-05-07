pragma solidity ^0.8.13;

import {CryticERC1155ExternalTestBase} from "./util/ERC1155ExternalTestBase.sol";
import {CryticERC1155ExternalBasicProperties} from "./properties/ERC1155ExternalBasicProperties.sol";
import {CryticERC1155ExternalBurnableProperties} from "./properties/ERC1155ExternalBurnableProperties.sol";
import {CryticERC1155ExternalMintableProperties} from "./properties/ERC1155ExternalMintableProperties.sol";

/// @notice Aggregator contract for various ERC1155 property tests. Inherit from this & echidna will test all properties at the same time.
abstract contract CryticERC1155ExternalPropertyTests is CryticERC1155ExternalBasicProperties, CryticERC1155ExternalMintableProperties, CryticERC1155ExternalBurnableProperties  {
    function _customMint(address to,uint id,uint amount) internal virtual override(CryticERC1155ExternalBasicProperties,CryticERC1155ExternalMintableProperties);
    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal virtual override(CryticERC1155ExternalBasicProperties,CryticERC1155ExternalBurnableProperties,CryticERC1155ExternalMintableProperties);
} 
