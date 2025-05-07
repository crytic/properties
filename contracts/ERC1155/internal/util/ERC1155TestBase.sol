pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesHelper.sol";
import {MockReceiver} from "./MockReceiver.sol";
import "../../../util/Hevm.sol";

abstract contract CryticERC1155TestBase is ERC1155, PropertiesAsserts, PropertiesConstants {

    // Is the contract allowed to change its total supply?
    bool isMintableOrBurnable;
    MockReceiver safeReceiver;
    MockReceiver unsafeReceiver;

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data )
        internal
        virtual
        override(ERC1155)
    {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
