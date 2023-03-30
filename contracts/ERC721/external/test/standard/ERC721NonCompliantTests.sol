pragma solidity ^0.8.0;

import {CryticERC721ExternalPropertyTests} from "../../ERC721ExternalPropertyTests.sol";
import {ERC721NonCompliant} from "../ERC721NonCompliant.sol";
import {IERC721Internal} from "../../../util/IERC721Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract TestHarness is CryticERC721ExternalPropertyTests {

    constructor() {
        token = IERC721Internal(address(new ERC721NonCompliant()));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }

}