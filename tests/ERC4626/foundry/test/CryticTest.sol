pragma solidity ^0.8.0;

import {CryticERC4626PropertyTests} from "properties/ERC4626/ERC4626PropertyTests.sol";
import {TestERC20Token} from "properties/ERC4626/util/TestERC20Token.sol";
import {Basic4626Impl} from "../src/Basic4626Impl.sol";

contract CryticERC4626InternalHarness is CryticERC4626PropertyTests {
    constructor() {
        TestERC20Token _asset = new TestERC20Token("Test Token", "TT", 18);
        Basic4626Impl _vault = new Basic4626Impl(address(_asset));
        initialize(address(_vault), address(_asset), false);
    }
}
