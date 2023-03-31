pragma solidity ^0.8.0;

import "./TokenMock.sol";
import {ITokenMock} from "./util/ITokenMock.sol";
import {CryticERC20ExternalBasicProperties} from "./properties/ERC20ExternalBasicProperties.sol";
import {CryticERC20ExternalBurnableProperties} from "./properties/ERC20ExternalBurnableProperties.sol";
import {CryticERC20ExternalMintableProperties} from "./properties/ERC20ExternalMintableProperties.sol";
import {CryticERC20ExternalPausableProperties} from "./properties/ERC20ExternalPausableProperties.sol";
import {CryticERC20ExternalIncreaseAllowanceProperties} from "./properties/ERC20ExternalIncreaseAllowanceProperties.sol";

contract CryticERC20ExternalPropertyTests is
    CryticERC20ExternalBasicProperties,
    CryticERC20ExternalIncreaseAllowanceProperties,
    CryticERC20ExternalBurnableProperties,
    CryticERC20ExternalMintableProperties,
    CryticERC20ExternalPausableProperties
{
    constructor() {
        // Deploy ERC20, mint initial balance to users (deployer is address(this))
        // If the token is mintable or burnable, the argument must be true. False otherwise.
        token = ITokenMock(address(new TokenMock(true)));
    }
}
