pragma solidity ^0.8.0;

import "../../../util/PropertiesHelper.sol";
import "../../util/IERC1155Internal.sol";
import "../../../util/PropertiesConstants.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {MockReceiver} from "./MockReceiver.sol";


abstract contract CryticERC1155ExternalTestBase is PropertiesAsserts, PropertiesConstants {
 
    // Is the contract allowed to change its total supply?
    bool isMintableOrBurnable;
    IERC1155Internal public token;
    MockReceiver public safeReceiver;
    MockReceiver public unsafeReceiver;

    constructor() {
    }

}
