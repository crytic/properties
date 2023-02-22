pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract CryticERC20BurnableProperties is CryticERC20Base, ERC20Burnable {

    constructor() {
        isMintableOrBurnable = true;
    }

    ////////////////////////////////////////
    // Properties

    // Burn should update user balance and total supply
    function test_ERC20_burn(uint256 amount) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 supply = totalSupply();
        require(balance_sender > 0);
        uint256 burn_amount = amount % (balance_sender+1);

        this.burn(burn_amount);
        assertEq(balanceOf(address(this)), balance_sender - burn_amount, "Source balance incorrect after burn");
        assertEq(totalSupply(), supply-burn_amount, "Total supply incorrect after burn");
    }

    // Burn should update user balance and total supply
    function test_ERC20_burnFrom(uint256 amount) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);
        uint256 supply = totalSupply();
        uint256 burn_amount = amount % (balance_sender+1);

        this.burnFrom(msg.sender, burn_amount);
        assertEq(balanceOf(msg.sender), balance_sender - burn_amount, "Source balance incorrect after burnFrom");
        assertEq(totalSupply(), supply-burn_amount, "Total supply incorrect after burnFrom");
    }

    // burnFrom should update allowance
    function test_ERC20_burnFromUpdateAllowance(uint256 amount) public {        
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 burn_amount = amount % (balance_sender+1);

        this.burnFrom(msg.sender, burn_amount);

        // Some implementations take an allowance of 2**256-1 as infinite, and therefore don't update
        if (current_allowance != type(uint256).max) {
            assertEq(allowance(msg.sender, address(this)), current_allowance - burn_amount, "Allowance not updated correctly");
        }
    }

}
