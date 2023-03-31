pragma solidity ^0.8.0;
import "@crytic/properties/ERC721/internal/properties/ERC721BasicProperties.sol";
import "../src/ExampleToken.sol";

contract CryticERC721InternalHarness is ExampleToken, CryticERC721BasicProperties {
    constructor() {
        isMintableOrBurnable = true;
    }
}
