// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import "./ExampleToken.sol";
import {ITokenMock} from "@crytic/properties/contracts/ERC20/external/util/ITokenMock.sol";
import {CryticERC20ExternalBasicProperties} from "@crytic/properties/contracts/ERC20/external/properties/ERC20ExternalBasicProperties.sol";

contract CryticERC20ExternalHarness is CryticERC20ExternalBasicProperties {
    constructor() {
        // Deploy ERC20
        token = ITokenMock(address(new TokenMock()));
    }
}

contract TokenMock is ExampleToken {
    // Address originating transactions in Echidna (must be equal to the `sender` configuration parameter)
    address constant USER1 = address(0x10000);
    address constant USER2 = address(0x20000);
    address constant USER3 = address(0x30000);

    // Initial balance for users' accounts
    uint256 constant INITIAL_BALANCE = 1000e18;

    bool public isMintableOrBurnable;
    uint256 public initialSupply;

    constructor() {
        _mint(USER1, INITIAL_BALANCE);
        _mint(USER2, INITIAL_BALANCE);
        _mint(USER3, INITIAL_BALANCE);
        _mint(msg.sender, INITIAL_BALANCE);

        initialSupply = totalSupply();
        isMintableOrBurnable = true;
    }
}
