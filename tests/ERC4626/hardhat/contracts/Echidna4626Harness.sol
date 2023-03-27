pragma solidity ^0.8.13;

import {CryticERC4626PropertyTests} from "@crytic/properties/contracts/ERC4626/ERC4626PropertyTests.sol";
import {TestERC20Token} from "@crytic/properties/contracts/ERC4626/util/TestERC20Token.sol";
import "./Basic4626Impl.sol";

contract CryticERC4626Harness is CryticERC4626PropertyTests {
    constructor() {
        TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
        ERC4626 _vault = new Basic4626Impl(address(_asset));
        initialize(address(_vault), address(_asset), false);
    }

    function test(uint256 a) public {}
}
