pragma solidity ^0.8.13;

import "../util/ERC1155ExternalTestBase.sol";
import "../../../util/Hevm.sol";
abstract contract CryticERC1155ExternalBasicProperties is CryticERC1155ExternalTestBase {
    using Address for address;
    mapping(uint256 => uint256) private idToAmount;
    
    ////////////////////////////////////////
    // Properties

    // Querying the balance of address(0) should throw
    function test_ERC1155_external_balanceOfZeroAddressMustRevert() public virtual {
        token.balanceOf(address(0),1);
        assertWithMsg(false, "address(0) balance query should have reverted");
    }

    // balanceOfBatch works as expected
    function test_ERC1155_external_balanceOfBatchWorksAsExpected(address[] memory targets,uint256[] memory ids,uint256[] memory amounts) public virtual{
        // target,ids and amounts should have same length.
        require(targets.length==ids.length);
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(targets[i],ids[i])==0);
        }
        
        // mint tokens to target
        for (uint256 i = 0; i < ids.length; i++) {
            _customMint(targets[i],ids[i],amounts[i]);
        }
        
        // check balanceOfBatch gives same balances
        uint256[] memory balances;
        balances = token.balanceOfBatch(targets,ids);
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(balances[i]==token.balanceOf(targets[i],ids[i]), "Failed to return expected balance amount to for id");
        }
    }

    // safeTransferFrom a token that the caller is not approved for should revert
     function test_ERC1155_external_transferFromNotApproved(address target, uint256 id,uint256 amount) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount);        
        require(target != address(this));
        require(target != msg.sender);
        
        bool isApproved = token.isApprovedForAll(msg.sender,address(this));
        require(!isApproved);

        token.safeTransferFrom( msg.sender, target, id, amount,"");
        assertWithMsg(false, "using safeTransferFrom without being approved should have reverted");
    }

    // safeTransferFrom correctly updates balance
    function test_ERC1155_external_transferFromUpdatesBalance(address target, uint256 id,uint256 amount) public virtual {
        uint256 selfBalanceBefore = token.balanceOf(msg.sender,id);
        uint256 targetBalanceBefore = token.balanceOf(target,id);
        require(selfBalanceBefore >= amount);
        require(target != address(this));
        require(target != msg.sender);
        require(!Address.isContract(target));
        hevm.prank(msg.sender);
        try token.safeTransferFrom(msg.sender,target, id,amount,"") {
        uint256 targetBalanceAfter = token.balanceOf(target,id);
        uint256 selfBalanceAfter = token.balanceOf(msg.sender,id);
            assertWithMsg(targetBalanceBefore+amount ==targetBalanceAfter, "Token balance of receiver not updated");
            assertWithMsg(selfBalanceBefore-amount ==selfBalanceAfter, "Token balance target not updated");
        } catch {
            assertWithMsg(false, "safeTransferFrom unexpectedly reverted");
        }
    }

    // transfer from zero address should revert/throw
    function test_ERC1155_transferFromZeroAddress(uint256 id,uint256 amount) public virtual {
        token.safeTransferFrom(address(0), msg.sender, id,amount,"");

        assertWithMsg(false, "Transfer from zero address did not revert");
    }

    // Transfers to the zero address should revert
        function test_ERC1155_external_transferFromToZeroAddress(uint256 id,uint256 amount) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount); 
        
        hevm.prank(msg.sender);
        token.safeTransferFrom(msg.sender, address(0), id,amount,"");

        assertWithMsg(false, "Transfer to zero address did not revert");
    }

    // Transfers to self should not break accounting
     function test_ERC1155_external_transferFromSelf(uint256 id,uint256 amount) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount); 
        
        hevm.prank(msg.sender);

        // transfer 1 token of id to self address from self address.
        try token.safeTransferFrom(msg.sender, msg.sender, id,amount,"") {
            assertWithMsg(selfBalance==token.balanceOf(msg.sender,id), "Self transfer breaks accounting");
        } catch {
            assertWithMsg(false, "safeTransferFrom unexpectedly reverted");
        }
    }

    // Batch transfer to self should not break accounting
    function test_ERC1155_external_safeBatchTransferFromSelf(uint256[] memory ids,uint256[] memory amounts) public virtual {
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]>0);
            require(token.balanceOf(msg.sender,ids[i])==0);
            idToAmount[ids[i]]+=amounts[i];
        }

        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        // balance for ids should be similar to amounts
        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }
        
        hevm.prank(msg.sender);
        
        // batch trasnfer tokens
        token.safeBatchTransferFrom(msg.sender,msg.sender,ids,amounts,"");

        // Balance should be same.
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(token.balanceOf(msg.sender,ids[i])==idToAmount[ids[i]], "Failed to mint expected balance amount to ids");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }
    }

    // safeBatchTransferFrom correctly updates balance
    function test_ERC1155_external_safeBatchTransferFrom(address target,uint256[] memory ids,uint256[] memory amounts) public virtual {
        // ids and amounts should have same length.
        require(ids.length==amounts.length);
        // sender's balance for ids should be equal to 0.
        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])==0);
            idToAmount[ids[i]]+=amounts[i];
        }

        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])==idToAmount[ids[i]]);
        }

        // receiver's balance for ids should be 0
        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(target,ids[i])==0);
        }

        hevm.prank(msg.sender);

        // batch transfer tokens
        token.safeBatchTransferFrom(msg.sender,target,ids,amounts,"");

        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(token.balanceOf(msg.sender,ids[i])==0, "Failed to update sender's balance");
        }

        // Balance should have increased
        for (uint256 i = 0; i < ids.length; i++) {
            assertWithMsg(token.balanceOf(target,ids[i])==idToAmount[ids[i]], "Failed to mint expected balance amount to target");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            delete idToAmount[ids[i]];
        }
    }

    // safeTransferFrom reverts if receiver does not implement the callback
    function test_ERC1155_external_safeTransferFromRevertsOnNoncontractReceiver(uint256 id,uint256 amount) public virtual {
        uint256 selfBalance = token.balanceOf(msg.sender,id);
        require(selfBalance >= amount); 
        
        hevm.prank(msg.sender);
        
        token.safeTransferFrom(msg.sender, address(unsafeReceiver), id,amount,"");
        assertWithMsg(false, "safeTransferFrom does not revert if receiver does not implement ERC1155.onERC1155Received");
    }

    // safeBatchTransferFrom reverts if receiver does not implement the callback
    function test_ERC1155_exernal_safeBatchTransferFromRevertsOnNoncontractReceiver(uint256[] memory ids,uint256[] memory amounts) public virtual {
        // ids and amounts should have same length.
        require(ids.length==amounts.length);

        // batch mint tokens
        _customMintBatch(msg.sender,ids,amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            require(token.balanceOf(msg.sender,ids[i])>=amounts[i]);
        }
        
        hevm.prank(msg.sender);
        token.safeBatchTransferFrom(msg.sender, address(unsafeReceiver), ids,amounts,"");
        assertWithMsg(false, "safeBatchTransferFrom does not revert if receiver does not implement ERC1155.onERC1155Received");
    }

    function _customMint(address to,uint id,uint amount) internal virtual;
    
    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal virtual;
}
