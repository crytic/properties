pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {CryticERC1155InternalPropertyTests} from "../../ERC1155InternalPropertyTests.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC1155Compliant is CryticERC1155InternalPropertyTests {
    using Address for address;

    constructor() ERC1155("url//") {
        isMintableOrBurnable = true;
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
    }

    function mintBatch(address target, uint256[] memory ids, uint256[] memory amounts) public {
        _mintBatch(target,ids,amounts,"");
    }

    function mint(address to,uint256 id,uint256 amount) public {
        _mint(to,id,amount,"");
    }

    function _customMint(address to,uint id,uint amount) internal override {
        mint(to,id,amount);
    }
    
    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal override{
        mintBatch(target,ids,amounts);
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data )
        internal
        virtual
        override
    {
        super._beforeTokenTransfer(operator,from,to,ids,amounts,data );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

contract ERC1155InternalCompliant is ERC1155Compliant {
    constructor() {}
}