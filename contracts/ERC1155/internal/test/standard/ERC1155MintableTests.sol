pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {CryticERC1155MintableProperties} from "../../properties/ERC1155MintableProperties.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC1155MintableTestsInternal is CryticERC1155MintableProperties {
    using Address for address;
    
    uint256 public counter;

    constructor() ERC1155("url//") {
        isMintableOrBurnable = true;
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
    }

    function mint(address to, uint256 id, uint256 amount) public {
        //require(totalSupply() + amount <= maxSupply);
        // _mint(to,id,amount,"");
    }

    function mintBatch(address target, uint256[] memory ids, uint256[] memory amounts) public {
        // _mintBatch(target,ids,amounts,"");
    }

    function _customMint(address to,uint id,uint amount) internal override {
        mint(to,id,amount);
    }
    
    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal override{
        mintBatch(target,ids,amounts);
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

contract ERC1155InternalMintable is ERC1155MintableTestsInternal {
    constructor() {}
}