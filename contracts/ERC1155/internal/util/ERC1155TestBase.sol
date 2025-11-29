// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesAsserts.sol";
import {MockReceiver1155} from "./MockReceiver1155.sol";
import "../../../util/IHevm.sol";

abstract contract CryticERC1155TestBase is
    ERC1155,
    PropertiesAsserts,
    PropertiesConstants
{
    // Is the contract allowed to change its total supply?
    bool isMintableOrBurnable;
    MockReceiver1155 safeReceiver;
    MockReceiver1155 unsafeReceiver;

    constructor(string memory uri) ERC1155(uri) {
        safeReceiver = new MockReceiver1155(true);
        unsafeReceiver = new MockReceiver1155(false);
    }
}
