// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CryticERC721ExternalBasicProperties} from "../../properties/ERC721ExternalBasicProperties.sol";
import {ERC721IncorrectBasic} from "../../util/ERC721IncorrectBasic.sol";
import {IERC721Internal} from "../../../util/IERC721Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract TestHarness is CryticERC721ExternalBasicProperties {
    constructor() {
        token = IERC721Internal(address(new ERC721IncorrectBasic("ERC721BAD","ERC721BAD")));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }
}