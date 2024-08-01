// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import {CryticERC721TestBase} from "./util/ERC721TestBase.sol";
import {CryticERC721BasicProperties} from "./properties/ERC721BasicProperties.sol";
import {CryticERC721BurnableProperties} from "./properties/ERC721BurnableProperties.sol";
import {CryticERC721MintableProperties} from "./properties/ERC721MintableProperties.sol";

/// @notice Aggregator contract for various ERC721 property tests. Inherit from this & echidna will test all properties at the same time.
abstract contract CryticERC721InternalPropertyTests is CryticERC721BasicProperties, CryticERC721MintableProperties, CryticERC721BurnableProperties  {

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(CryticERC721BurnableProperties, CryticERC721TestBase)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CryticERC721BurnableProperties, CryticERC721TestBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
} 
