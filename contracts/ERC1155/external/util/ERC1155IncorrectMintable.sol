pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155IncorrectMintable is ERC1155{
    bool public isMintableOrBurnable;
    constructor() ERC1155("tokenUrl//") {isMintableOrBurnable=true;}

    function mintBatch(address target, uint256[] memory ids, uint256[] memory amounts) public {
        //_mintBatch(target,ids,amounts,"");
    }

    function mint(address to,uint256 id,uint256 amount) public {
        //_mint(to,id,amount,"");
    }

    // function burn(address account, uint256 id, uint256 amount) public virtual override{
    //     // require( account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not token owner or approved" );
    //     if (id % 2 == 0) {
    //         _mint(account,id,amount,"");
    //     } else {
    //         _burn(account, id, amount);
    //     }
    // }

    // function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public virtual override{
    //     //require( account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not token owner or approved" );
    //     for( uint256 i;i<ids.length;i++){
    //         if (ids[i] % 2 == 0) {
    //              _mint(account,ids[i],amounts[i],"");
    //         } else {
    //             _burn(account,ids[i],amounts[i]);
    //         }
    //     }
    // }

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