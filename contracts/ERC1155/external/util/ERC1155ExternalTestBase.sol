// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesAsserts.sol";
import "../../util/IERC1155Internal.sol";
import {MockReceiver1155} from "../../internal/util/MockReceiver1155.sol";

abstract contract CryticERC1155ExternalTestBase is PropertiesAsserts, PropertiesConstants {
    IERC1155Internal internal token;
    MockReceiver1155 safeReceiver;
    MockReceiver1155 unsafeReceiver;

    constructor() {
        safeReceiver = new MockReceiver1155(true);
        unsafeReceiver = new MockReceiver1155(false);
    }
}
