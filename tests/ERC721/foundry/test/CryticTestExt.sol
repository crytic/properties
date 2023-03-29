pragma solidity ^0.8.0;
import "../src/ExampleToken.sol";
import {IERC721Mock} from "properties/ERC721/external/util/IERC721Mock.sol";
import {CryticERC721ExternalBasicProperties} from "properties/ERC721/external/properties/ERC721xternalBasicProperties.sol";

contract CryticERC721ExternalHarness is CryticERC721ExternalBasicProperties {
        
    constructor() {
        // Deploy ERC721
        token = IERC721Mock(address(new ERC721Mock()));
    }

}

contract ERC721Mock is ExampleToken {

    // Address originating transactions in Echidna (must be equal to the `sender` configuration parameter)
    address constant USER1 = address(0x10000);
    address constant USER2 = address(0x20000);
    address constant USER3 = address(0x30000);

    // Initial balance for users' accounts
    uint256 constant INITIAL_BALANCE = 5;

    bool public isMintableOrBurnable;
    uint256 public initialSupply;
    constructor () {
        for(uint256 i; i < INITIAL_BALANCE; i=i + 4) {
        _mint(USER1, i);
        _mint(USER2, i+1);
        _mint(USER3, i+2);
        _mint(msg.sender, i+3);
        }
        

        initialSupply = totalSupply();
        isMintableOrBurnable = true;
    }

}
