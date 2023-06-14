pragma solidity ^0.8.0;

import {CryticERC1155ExternalMintableProperties} from "../../properties/ERC1155ExternalMintableProperties.sol";
import {ERC1155IncorrectMintable} from "../../util/ERC1155IncorrectMintable.sol";
import {IERC1155Internal} from "../../../util/IERC1155Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC1155MintableExternalHarness is CryticERC1155ExternalMintableProperties {
    constructor() {
        token = IERC1155Internal(address(new ERC1155IncorrectMintable()));
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