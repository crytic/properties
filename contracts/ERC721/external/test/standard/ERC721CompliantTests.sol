pragma solidity ^0.8.0;

import {CryticERC721ExternalPropertyTests} from "../../ERC721ExternalPropertyTests.sol";
import {ERC721Compliant} from "../ERC721Compliant.sol";
import {IERC721Internal} from "../../../util/IERC721Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract TestHarness is CryticERC721ExternalPropertyTests {

    constructor() {
        token = IERC721Internal(address(new ERC721Compliant()));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }

}