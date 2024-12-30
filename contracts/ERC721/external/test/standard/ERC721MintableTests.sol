// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CryticERC721ExternalMintableProperties} from "../../properties/ERC721ExternalMintableProperties.sol";
import {ERC721IncorrectMintable} from "../../util/ERC721IncorrectMintable.sol";
import {IERC721Internal} from "../../../util/IERC721Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract TestHarness is CryticERC721ExternalMintableProperties {
    constructor() {
        token = IERC721Internal(address(new ERC721IncorrectMintable("ERC721BAD","ERC721BAD")));
        mockSafeReceiver = new MockReceiver(true);
        mockUnsafeReceiver = new MockReceiver(false);
    }
}