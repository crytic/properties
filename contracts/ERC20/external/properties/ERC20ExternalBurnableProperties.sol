pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";

abstract contract CryticERC20ExternalBurnableProperties is CryticERC20ExternalTestBase {

    constructor() {
        
    }

    ////////////////////////////////////////
    // Properties

    // Burn should update user balance and total supply
    function test_ERC20external_burn(uint256 amount) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 supply = token.totalSupply();
        require(balance_sender > 0);
        uint256 burn_amount = amount % (balance_sender+1);

        token.burn(burn_amount);
        assertEq(token.balanceOf(address(this)), balance_sender - burn_amount, "Source balance incorrect after burn");
        assertEq(token.totalSupply(), supply-burn_amount, "Total supply incorrect after burn");
    }

    // Burn should update user balance and total supply
    function test_ERC20external_burnFrom(uint256 amount) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 supply = token.totalSupply();
        uint256 burn_amount = amount % (balance_sender+1);

        token.burnFrom(msg.sender, burn_amount);
        assertEq(token.balanceOf(msg.sender), balance_sender - burn_amount, "Source balance incorrect after burnFrom");
        assertEq(token.totalSupply(), supply-burn_amount, "Total supply incorrect after burnFrom");
    }

    // burnFrom should update allowance
    function test_ERC20external_burnFromUpdateAllowance(uint256 amount) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 current_allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 burn_amount = amount % (balance_sender+1);

        token.burnFrom(msg.sender, burn_amount);

        // Some implementations take an allowance of 2**256-1 as infinite, and therefore don't update
        if (current_allowance != type(uint256).max) {
            assertEq(token.allowance(msg.sender, address(this)), current_allowance - burn_amount, "Allowance not updated correctly");
        }
    }

}
