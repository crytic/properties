pragma solidity ^0.8.0;

import "../../../util/PropertiesHelper.sol";
import "../../util/IERC721Internal.sol";
import "../../../util/PropertiesConstants.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {MockReceiver} from "./MockReceiver.sol";


abstract contract CryticERC721ExternalTestBase is PropertiesAsserts, PropertiesConstants {

    IERC721Internal token;
    MockReceiver mockSafeReceiver;
    MockReceiver mockUnsafeReceiver;

    constructor() {
    }

}
