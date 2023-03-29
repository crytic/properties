pragma solidity ^0.8.0;
import "properties/ERC721/internal/properties/ERC721BasicProperties.sol";
import "../src/ExampleToken.sol";

contract CryticERC721InternalHarness is ExampleToken, CryticERC721BasicProperties {
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
