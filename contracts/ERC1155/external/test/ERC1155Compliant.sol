pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract ERC1155Compliant is ERC1155, ERC1155Burnable {
    bool public isMintableOrBurnable;
    constructor() ERC1155("tokenUrl//") {isMintableOrBurnable=true;}

    function mintBatch(address target, uint256[] memory ids, uint256[] memory amounts) public {
        _mintBatch(target,ids,amounts,"");
    }

    function mint(address to,uint256 id,uint256 amount) public {
        _mint(to,id,amount,"");
    }

    // Overrides

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