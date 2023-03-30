pragma solidity ^0.8.0;

import "../../../util/PropertiesHelper.sol";
import "./IERC721Mock.sol";
import "../../../util/PropertiesConstants.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {MockReceiver} from "./MockReceiver.sol";


abstract contract CryticERC721ExternalTestBase is PropertiesAsserts, PropertiesConstants {

    IERC721Mock token;
    MockReceiver mockSafeReceiver;
    MockReceiver mockUnsafeReceiver;

    constructor() {
    }

}
