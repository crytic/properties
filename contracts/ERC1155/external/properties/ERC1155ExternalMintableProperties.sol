pragma solidity ^0.8.13;

import "../util/ERC1155ExternalTestBase.sol";

abstract contract CryticERC1155ExternalMintableProperties is CryticERC1155ExternalTestBase {
    mapping(uint256 => uint256) private idToAmount;
    ////////////////////////////////////////
    // Properties
    // mint increases the total supply
    function test_ERC1155_external_mint(uint id,uint amount) public virtual {
        require(isMintableOrBurnable);
        // Check the target has 0 balance
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        
        _customMint(msg.sender,id,amount);

        assertWithMsg(token.balanceOf(msg.sender,id)==selfBalance+amount, "Token balance of receiver not updated");
    }

    //_mintBatch Should mint tokens in batch
    function test_ERC1155_external_mintBatchTokens(address target, uint256[] memory ids, uint256[] memory amounts) public virtual{
        require(isMintableOrBurnable);
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        // balance for ids should be zero
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            require(token.balanceOf(target,ids[i])==0);
            idToAmount[ids[i]]+=amounts[i];
        }

        // batch mint tokens
        _customMintBatch(target,ids,amounts);

        // Balance should have increased
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(token.balanceOf(target,ids[i])==idToAmount[ids[i]], "Failed to mint expected balance amount to ids");   
        }

        // deleting element in above loop will cause problem when there would be duplicate element in ids.
        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }
    }

    // Wrappers
    function _customMint(address to,uint id,uint amount) internal virtual;
    
    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal virtual;
}