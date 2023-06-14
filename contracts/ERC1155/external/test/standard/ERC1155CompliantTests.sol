pragma solidity ^0.8.0;

import {CryticERC1155ExternalPropertyTests} from "../../ERC1155ExternalPropertyTests.sol";
import {ERC1155Compliant} from "../ERC1155Compliant.sol";
import {IERC1155Internal} from "../../../util/IERC1155Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC1155CompliantExternalHarness is CryticERC1155ExternalPropertyTests {
    constructor() {
        token = IERC1155Internal(address(new ERC1155Compliant()));
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
        isMintableOrBurnable=true;
    }

    function _customMint(address to,uint id,uint amount) internal override {
        token.mint(to,id,amount);
    }

    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal override{
        token.mintBatch(target,ids,amounts);
    }
}