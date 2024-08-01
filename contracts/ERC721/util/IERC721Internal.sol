// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Internal is IERC721, IERC721Enumerable {
    function isMintableOrBurnable() external returns (bool);
    function burn(uint256 tokenId) external;
    function usedId(uint256 tokenId) external view returns (bool);
    function _customMint(address to, uint256 amount) external;
}