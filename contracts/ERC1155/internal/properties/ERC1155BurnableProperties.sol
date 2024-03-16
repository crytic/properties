pragma solidity ^0.8.13;

import "../util/ERC1155TestBase.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract CryticERC1155BurnableProperties is CryticERC1155TestBase,ERC1155Burnable {
    using Address for address;
    mapping(uint256 => uint256) private idToAmount;
    ////////////////////////////////////////
    // Properties

    // The burn function should destroy tokens and balance
    function test_ERC1155_burnDestroysTokens(uint256 id,uint256 amount) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender,id);
        require(selfBalance >= amount);

        burn(msg.sender,id,selfBalance);

        assertWithMsg(balanceOf(msg.sender,id) == 0, "failed to update balance after burning");
    }

    // The approved address should be able to destroy tokens
    function test_ERC1155_burnDestroysTokensFromApprovedAddress(address target, uint256 id,uint256 amount) public virtual {
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender,id);
        require(selfBalance >= amount);
        require(target != msg.sender);

        // set approval
        setApprovalForAll(target,true);

        hevm.prank(target);
        burn(msg.sender,id,selfBalance);

        assertWithMsg(balanceOf(msg.sender,id) == 0, "failed to update balance after burning");
    }
    
    // A burned token should not be transferrable
    function test_ERC1155_burnRevertOnTransferFromPreviousOwner(address target,uint256 id,uint256 amount) public virtual{
        require(isMintableOrBurnable);
        uint256 selfBalance = balanceOf(msg.sender,id);
        require(selfBalance >= amount);

        burn(msg.sender,id,selfBalance);

        safeTransferFrom(msg.sender,target, id,1,"");
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    // burned token(s) should not be transferrable when burned with burnBatch
    function test_ERC1155_burnBatchRevertOnTransferFromPreviousOwner(address target,uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(isMintableOrBurnable);
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            idToAmount[ids[i]]+=amounts[i];
            require(balanceOf(msg.sender,ids[i])==0);
        }
        
        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
        for (uint256 i = 0; i < ids.length; i++) {
            require(balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }

        // batch burn tokens
        burnBatch(msg.sender,ids,amounts);

        safeBatchTransferFrom(msg.sender,target,ids,amounts,"");

        assertWithMsg(false, "Transferring burned tokens didn't revert");
    }

    

    function test_ERC1155_burnBatchDestroysTokens(uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(isMintableOrBurnable);
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            idToAmount[ids[i]]+=amounts[i];
            require(balanceOf(msg.sender,ids[i])==0);
        }
        
        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
         for (uint256 i = 0; i < ids.length; i++) {
            require(balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }

        // batch burn tokens
        burnBatch(msg.sender,ids,amounts);

        // Balance should have decreased
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(balanceOf(msg.sender,ids[i])==0, "Failed to burn expected balance amount to ids");
        }
    }

    function test_ERC1155_burnBatchDestroysTokensFromApprovedAddress(address target, uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(isMintableOrBurnable);
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        require(target != msg.sender);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            idToAmount[ids[i]]+=amounts[i];
            require(balanceOf(msg.sender,ids[i])==0);
        }
        
        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
         for (uint256 i = 0; i < ids.length; i++) {
            require(balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }

        // set approval
        setApprovalForAll(target,true);

        hevm.prank(target);
        // batch burn tokens
        burnBatch(msg.sender,ids,amounts);

        // Balance should have decreased
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(balanceOf(msg.sender,ids[i])==0, "Failed to burn expected balance amount to ids");
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data )
        internal
        virtual
        override(ERC1155, CryticERC1155TestBase)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, CryticERC1155TestBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal virtual;
}
