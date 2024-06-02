pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Internal is IERC1155 {
    function isMintableOrBurnable() external returns (bool);
    function burn(address account,uint256 id,uint256 value) external;
    function mint(address to,uint256 id,uint256 amount) external;
    function _customMint(address to,uint id,uint amount) external;
    function mintBatch(address target, uint256[] memory ids, uint256[] memory amounts) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}