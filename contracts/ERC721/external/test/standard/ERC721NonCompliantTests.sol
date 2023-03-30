pragma solidity ^0.8.0;

import {CryticERC721ExternalPropertyTests} from "../../ERC721ExternalPropertyTests.sol";
import {ERC721NonCompliant} from "../ERC721NonCompliant.sol";
import {IERC721Mock} from "../../util/IERC721Mock.sol";

contract TestHarness is CryticERC721ExternalPropertyTests {

    constructor() {
        token = IERC721Mock(address(new ERC721NonCompliant()));
    }

    function _customMint(uint256 amount) internal virtual override {}

}