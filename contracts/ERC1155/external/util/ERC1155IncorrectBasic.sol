pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155IncorrectBasic is ERC1155{
    bool public isMintableOrBurnable;
    constructor() ERC1155("tokenUrl//") {isMintableOrBurnable=true;}

    function mintBatch(address target, uint256[] memory ids, uint256[] memory amounts) public {
        //_mintBatch(target,ids,amounts,"");
    }

    function mint(address to,uint256 id,uint256 amount) public {
        //_mint(to,id,amount,"");
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        // require(account != address(0), "ERC1155: address zero is not a valid owner");
        return account == address(0) ? 0 : super.balanceOf(account,id);
    }

    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data ) public virtual override {
        //solhint-disable-next-line max-line-length
        // require( from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not token owner or approved" );
        if (from == to) {
            _mint(to,id,amount,"");
        }
    }

    function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) public virtual override {
        // require( from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not token owner or approved" );
        if (from == to) {
            _mintBatch(to,ids,amounts,"");
        }
    }

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