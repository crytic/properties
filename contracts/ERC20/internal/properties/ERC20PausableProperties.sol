pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

abstract contract CryticERC20PausableProperties is
    CryticERC20Base,
    ERC20Pausable
{
    constructor() {}

    ////////////////////////////////////////
    // Helper functions - May need tweaking for non-OZ tokens

    function _overridePause(bool paused) internal {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    // Override for pausable tokens
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }

    ////////////////////////////////////////
    // Properties

    // Transfers should not be possible during paused state
    function test_ERC20_pausedTransfer(address target, uint256 amount) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 0);
        uint256 transfer_amount = amount % (balance_sender + 1);

        _pause();

        bool r = this.transfer(target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(
            balanceOf(address(this)),
            balance_sender,
            "Transfer while paused altered source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Transfer while paused altered target balance"
        );

        _unpause();
    }

    // Transfers should not be possible during paused state
    function test_ERC20_pausedTransferFrom(
        address target,
        uint256 amount
    ) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 transfer_amount = amount % (balance_sender + 1);

        _pause();

        bool r = this.transferFrom(msg.sender, target, transfer_amount);
        assertWithMsg(r == false, "Tokens transferred while paused");
        assertEq(
            balanceOf(msg.sender),
            balance_sender,
            "Transfer while paused altered source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Transfer while paused altered target balance"
        );

        _unpause();
    }
}
