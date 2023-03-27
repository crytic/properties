pragma solidity ^0.8.0;

import "../../util/PropertiesConstants.sol";
import "./ExampleToken.sol";

contract TokenMock is ExampleToken, PropertiesConstants {
    bool public isMintableOrBurnable;
    uint256 public initialSupply;

    constructor(bool _isMintableOrBurnable) {
        _mint(USER1, INITIAL_BALANCE);
        _mint(USER2, INITIAL_BALANCE);
        _mint(USER3, INITIAL_BALANCE);
        _mint(msg.sender, INITIAL_BALANCE);

        initialSupply = totalSupply();
        isMintableOrBurnable = _isMintableOrBurnable;
    }
}
