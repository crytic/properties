// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Low Decimals Token
 * @notice ERC20 token with only 6 decimals (vs standard 18)
 * @dev Mimics tokens like USDC (6 decimals) or Gemini USD (2 decimals)
 * @custom:example-tokens USDC (6), Gemini USD (2)
 * @custom:impact Larger precision loss in calculations
 * @custom:see https://github.com/d-xo/weird-erc20#low-decimals
 */
contract LowDecimals {
    string public name = "Low Decimals Token";
    string public symbol = "LOW";
    uint8 public decimals = 6; // USDC-like decimals
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        totalSupply = 1000000e6; // Note: 6 decimals
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
