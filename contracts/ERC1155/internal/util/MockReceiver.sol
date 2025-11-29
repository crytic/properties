pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MockReceiver is ERC1155Holder {
    bool shouldReceive;

    constructor(bool _shouldReceive) {
        shouldReceive = _shouldReceive;
    }

    function onERC1155Received( address, address, uint256, uint256, bytes memory ) public virtual override returns (bytes4) {
        if (shouldReceive) {
            return this.onERC1155Received.selector;
        }

        return bytes4(0);
    }

    function onERC1155BatchReceived( address, address, uint256[] memory, uint256[] memory, bytes memory ) public virtual override returns (bytes4) {
        if (shouldReceive) {
            return this.onERC1155BatchReceived.selector;
        }

        return bytes4(0);
    }
}