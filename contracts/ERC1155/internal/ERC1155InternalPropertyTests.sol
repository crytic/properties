pragma solidity ^0.8.13;

import {CryticERC1155TestBase} from "./util/ERC1155TestBase.sol";
import {CryticERC1155BasicProperties} from "./properties/ERC1155BasicProperties.sol";
import {CryticERC1155BurnableProperties} from "./properties/ERC1155BurnableProperties.sol";
import {CryticERC1155MintableProperties} from "./properties/ERC1155MintableProperties.sol";

/// @notice Aggregator contract for various ERC1155 property tests. Inherit from this & echidna will test all properties at the same time.
abstract contract CryticERC1155InternalPropertyTests is CryticERC1155BasicProperties, CryticERC1155MintableProperties, CryticERC1155BurnableProperties  {

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data )
        internal
        virtual
        override(CryticERC1155TestBase,CryticERC1155BurnableProperties)
    {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CryticERC1155BurnableProperties, CryticERC1155TestBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _customMint(address to,uint id,uint amount) internal virtual override(CryticERC1155BasicProperties,CryticERC1155MintableProperties);

    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal virtual override(CryticERC1155BasicProperties,CryticERC1155BurnableProperties,CryticERC1155MintableProperties);
} 
