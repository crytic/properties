pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Internal is IERC721, IERC721Enumerable {
    function isMintableOrBurnable() external returns (bool);
    function burn(uint256 tokenId) external;
    function _customMint(uint256 amount) external;
    function _customMaxSupply() external view returns (uint256);
}