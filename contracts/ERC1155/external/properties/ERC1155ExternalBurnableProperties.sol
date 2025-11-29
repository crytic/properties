pragma solidity ^0.8.13;

import "../util/ERC1155ExternalTestBase.sol";
import "../../../util/Hevm.sol";

abstract contract CryticERC1155ExternalBurnableProperties is CryticERC1155ExternalTestBase{
    using Address for address;
    mapping(uint256 => uint256) private idToAmount;
    ////////////////////////////////////////
    // Properties

    // The burn function should destroy tokens and balance
    function test_ERC1155_external_burnDestroysTokens(uint256 id,uint256 amount) public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount);
        
        hevm.prank(msg.sender);
        token.burn(msg.sender,id,selfBalance);

        assertWithMsg(token.balanceOf(msg.sender,id) == 0, "failed to update balance after burning");
    }

    function test_ERC1155_external_burnDestroysTokensFromApprovedAddress(address target,uint256 id,uint256 amount) public virtual {
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount);
        require(target != msg.sender);
        
        // set approval
        hevm.prank(msg.sender);
        token.setApprovalForAll(target,true);

        hevm.prank(target);
        token.burn(msg.sender,id,selfBalance);

        assertWithMsg(token.balanceOf(msg.sender,id) == 0, "failed to update balance after burning");
    }
    
    // A burned token should not be transferrable
    function test_ERC1155_external_burnRevertOnTransferFromPreviousOwner(address target,uint256 id,uint256 amount) public virtual{
        require(token.isMintableOrBurnable());
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount);
        
        hevm.prank(msg.sender);
        token.burn(msg.sender,id,selfBalance);

        token.safeTransferFrom(msg.sender,target, id,1,"");
        assertWithMsg(false, "Transferring a burned token didn't revert");
    }

    // burned token(s) should not be transferrable when burned with burnBatch
    function test_ERC1155_external_burnBatchRevertOnTransferFromPreviousOwner(address target,uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(token.isMintableOrBurnable());
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            idToAmount[ids[i]]+=amounts[i];
            require(token.balanceOf(msg.sender,ids[i])==0);
        }
        
        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }
        
        // batch burn tokens
        hevm.prank(msg.sender);
        token.burnBatch(msg.sender,ids,amounts);

        hevm.prank(msg.sender);
        token.safeBatchTransferFrom(msg.sender,target,ids,amounts,"");

        assertWithMsg(false, "Transferring burned tokens didn't revert");
    }

    function test_ERC1155_external_burnBatchDestroysTokens(uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(token.isMintableOrBurnable());
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            idToAmount[ids[i]]+=amounts[i];
            require(token.balanceOf(msg.sender,ids[i])==0);
        }
        
        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
         for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }

        hevm.prank(msg.sender);
        // batch burn tokens
        token.burnBatch(msg.sender,ids,amounts);

        // Balance should have decreased
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(token.balanceOf(msg.sender,ids[i])==0, "Failed to burn expected balance amount to ids");
        }
    }

    function test_ERC1155_external_burnBatchDestroysTokensFromApprovedAddress(address target, uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(token.isMintableOrBurnable());
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        require(target != msg.sender);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            idToAmount[ids[i]]+=amounts[i];
            require(token.balanceOf(msg.sender,ids[i])==0);
        }
        
        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
         for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }

        // set approval
        hevm.prank(msg.sender);
        token.setApprovalForAll(target,true);

        hevm.prank(target);
        // batch burn tokens
        token.burnBatch(msg.sender,ids,amounts);

        // Balance should have decreased
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(token.balanceOf(msg.sender,ids[i])==0, "Failed to burn expected balance amount to ids");
        }
    }

    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal virtual;
}
