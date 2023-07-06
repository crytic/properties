pragma solidity ^0.8.0;
import "./ExampleToken.sol";
import {IERC721Internal} from "@crytic/properties/contracts/ERC721/util/IERC721Internal.sol";
import {CryticERC721ExternalBasicProperties} from "@crytic/properties/contracts/ERC721/external/properties/ERC721ExternalBasicProperties.sol";
import {MockReceiver} from "@crytic/properties/contracts/ERC721/external/util/MockReceiver.sol";

contract CryticERC721ExternalHarness is CryticERC721ExternalBasicProperties {
        
    constructor() {
        // Deploy ERC721
        token = IERC721Internal(address(new ERC721Mock()));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }

}

contract ERC721Mock is ExampleToken {

    // Address originating transactions in Echidna (must be equal to the `sender` configuration parameter)
    address constant USER1 = address(0x10000);
    address constant USER2 = address(0x20000);
    address constant USER3 = address(0x30000);

    bool public isMintableOrBurnable;
    constructor () {
        isMintableOrBurnable = true;
    }

}
