pragma solidity ^0.8.0;

import {CryticERC1155ExternalBasicProperties} from "../../properties/ERC1155ExternalBasicProperties.sol";
import {ERC1155IncorrectBasic} from "../../util/ERC1155IncorrectBasic.sol";
import {IERC1155Internal} from "../../../util/IERC1155Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC1155BasicExternalHarness is CryticERC1155ExternalBasicProperties {
    constructor() {
        token = IERC1155Internal(address(new ERC1155IncorrectBasic()));
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
    }

    function _customMint(address to,uint id,uint amount) internal override {
        token.mint(to,id,amount);
    }

    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal override{
        token.mintBatch(target,ids,amounts);
    }
}