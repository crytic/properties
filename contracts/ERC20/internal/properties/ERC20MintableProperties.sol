pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";

abstract contract CryticERC20MintableProperties is CryticERC20Base {

    constructor() {
        isMintableOrBurnable = true;
    }

    // Should be modified if target contract's function name is not mint
    function mint(address to, uint256 amount) public virtual;

    ////////////////////////////////////////
    // Properties

    // Minting tokens should update user balance and total supply
    function test_ERC20_mintTokens(address target, uint256 amount) public {
        uint256 balance_receiver = balanceOf(target);
        uint256 supply = totalSupply();

        this.mint(target, amount);
        assertEq(balanceOf(target), balance_receiver+amount, "Mint failed to update target balance");
        assertEq(totalSupply(), supply+amount, "Mint failed to update total supply");
    }
}
