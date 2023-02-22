pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";
import "../../../util/Hevm.sol";

abstract contract CryticERC20ExternalPausableProperties is CryticERC20ExternalTestBase {

    constructor() {
        
    }

    ////////////////////////////////////////
    // Properties

    // Transfers should not be possible during paused state
    function test_ERC20external_pausedTransfer(address target, uint256 amount) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 0);
        uint256 transfer_amount = amount % (balance_sender+1);

        hevm.prank(token.owner());
        token.pause();

        bool r = token.transfer(target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(token.balanceOf(address(this)), balance_sender, "Transfer while paused altered source balance");
        assertEq(token.balanceOf(target), balance_receiver, "Transfer while paused altered target balance");

        hevm.prank(token.owner());
        token.unpause();
    }

    // Transfers should not be possible during paused state
    function test_ERC20external_pausedTransferFrom(address target, uint256 amount) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 transfer_amount = amount % (balance_sender+1);

        hevm.prank(token.owner());
        token.pause();

        bool r = token.transferFrom(msg.sender, target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(token.balanceOf(msg.sender), balance_sender, "Transfer while paused altered source balance");
        assertEq(token.balanceOf(target), balance_receiver, "Transfer while paused altered target balance");

        hevm.prank(token.owner());
        token.unpause();
    }

}
