pragma solidity ^0.8.0;

import "../../../util/IERC20.sol";

interface ITokenMock is IERC20 {
    function isMintableOrBurnable() external returns (bool);
    function initialSupply() external returns (uint256);

    function burn(uint256) external;
    function burnFrom(address, uint256) external;
    function mint(address, uint256) external;
    function pause() external;
    function unpause() external;
    function paused() external returns (bool);
    function owner() external returns (address);
    function increaseAllowance(address, uint256) external returns (bool);
    function decreaseAllowance(address, uint256) external returns (bool);
}