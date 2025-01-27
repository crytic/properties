pragma solidity ^0.8.0;

import {CryticERC1155ExternalBurnableProperties} from "../../properties/ERC1155ExternalBurnableProperties.sol";
import {ERC1155IncorrectBurnable} from "../../util/ERC1155IncorrectBurnable.sol";
import {IERC1155Internal} from "../../../util/IERC1155Internal.sol";
import {MockReceiver} from "../../util/MockReceiver.sol";

contract ERC1155BurnableExternalHarness is CryticERC1155ExternalBurnableProperties {
    constructor() {
        token = IERC1155Internal(address(new ERC1155IncorrectBurnable()));
        safeReceiver = new MockReceiver(true);
        unsafeReceiver = new MockReceiver(false);
    }

    function _customMintBatch(address target, uint256[] memory ids, uint256[] memory amounts) internal override{
        token.mintBatch(target,ids,amounts);
    }


}