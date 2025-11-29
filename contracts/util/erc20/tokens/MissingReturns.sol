// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Missing Returns Token
 * @notice ERC20 token that does not return bool from transfer functions
 * @dev Mimics tokens like USDT, BNB, OMG that have no return values
 * @custom:example-tokens USDT, BNB, OMG
 * @custom:impact Contracts expecting return values will fail when decoding
 * @custom:see https://github.com/d-xo/weird-erc20#missing-return-values
 */
contract MissingReturns {
    string public name = "Missing Returns Token";
    string public symbol = "MISS";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 1000000e18;
        balanceOf[msg.sender] = totalSupply;
    }

    // NO RETURN VALUE - violates ERC20 standard
    function transfer(address to, uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    // NO RETURN VALUE - violates ERC20 standard
    function transferFrom(address from, address to, uint256 amount) public {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
