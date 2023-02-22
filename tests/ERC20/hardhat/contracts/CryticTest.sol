pragma solidity ^0.8.13;
import "@crytic/properties/contracts/ERC20/internal/properties/ERC20BasicProperties.sol";
import "./ExampleToken.sol";

contract CryticERC20InternalHarness is ExampleToken, CryticERC20BasicProperties {
    constructor() {
        // Setup balances for USER1, USER2 and USER3:
        _mint(USER1, INITIAL_BALANCE);
        _mint(USER2, INITIAL_BALANCE);
        _mint(USER3, INITIAL_BALANCE);
        // Setup total supply:
        initialSupply = totalSupply();
        isMintableOrBurnable = true;
    }
}
