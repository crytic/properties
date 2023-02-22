pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../util/PropertiesConstants.sol";
import "../../../util/PropertiesHelper.sol";

abstract contract CryticERC20Base is ERC20, PropertiesAsserts, PropertiesConstants {

    // Initial supply after deploying
    uint256 initialSupply;

    // Is the contract allowed to change its total supply?
    bool isMintableOrBurnable;

    constructor() {
    }

}
