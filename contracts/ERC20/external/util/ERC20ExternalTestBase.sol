pragma solidity ^0.8.0;

import "../../../util/PropertiesHelper.sol";
import "./ITokenMock.sol";
import "../../../util/PropertiesConstants.sol";

abstract contract CryticERC20ExternalTestBase is PropertiesAsserts, PropertiesConstants {

    ITokenMock token;

    constructor() {
    }

}
