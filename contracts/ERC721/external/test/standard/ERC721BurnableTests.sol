// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CryticERC721ExternalBurnableProperties} from "../../properties/ERC721ExternalBurnableProperties.sol";
import {ERC721IncorrectBurnable} from "../../util/ERC721IncorrectBurnable.sol";
import {IERC721Internal} from "../../../util/IERC721Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract TestHarness is CryticERC721ExternalBurnableProperties {
    constructor() {
        token = IERC721Internal(address(new ERC721IncorrectBurnable("ERC721BAD","ERC721BAD")));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }
}