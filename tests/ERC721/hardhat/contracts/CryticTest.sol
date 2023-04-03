pragma solidity ^0.8.0;
import "@crytic/properties/ERC721/internal/properties/ERC721BasicProperties.sol";
import "./ExampleToken.sol";

contract CryticERC721InternalHarness is ExampleToken, CryticERC721BasicProperties {
    constructor() {
        isMintableOrBurnable = true;
    }

    function _customMint(uint256 amount) internal virtual {
        mint(amount);
    }

    function _customMaxSupply() internal virtual view returns (uint256) {
        return maxSupply;
    }
}
