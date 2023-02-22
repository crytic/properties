pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";

abstract contract CryticERC20ExternalMintableProperties is CryticERC20ExternalTestBase {

    constructor() {
        
    }

    ////////////////////////////////////////
    // Properties

    // Minting tokens should update user balance and total supply
    function test_ERC20external_mintTokens(address target, uint256 amount) public {
        uint256 balance_receiver = token.balanceOf(target);
        uint256 supply = token.totalSupply();

        token.mint(target, amount);
        assertEq(token.balanceOf(target), balance_receiver+amount, "Mint failed to update target balance");
        assertEq(token.totalSupply(), supply+amount, "Mint failed to update total supply");
    }
}
