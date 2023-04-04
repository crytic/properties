pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract MockReceiver is ERC721Holder {
    bool shouldReceive;

    constructor(bool _shouldReceive) {
        shouldReceive = _shouldReceive;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        if (shouldReceive) {
            return this.onERC721Received.selector;
        }

        return bytes4(0);
    }
}