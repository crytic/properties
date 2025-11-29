// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Returns False Token
 * @notice ERC20 token that returns false even on successful transfers
 * @dev Mimics tokens like Tether Gold that return false despite success
 * @custom:example-tokens Tether Gold (XAUT)
 * @custom:impact Makes it impossible to correctly handle return values for all tokens
 * @custom:see https://github.com/d-xo/weird-erc20#missing-return-values
 */
contract ReturnsFalse {
    string public name = "Returns False Token";
    string public symbol = "FALSE";
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

    // Returns false even though transfer succeeds
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return false; // Returns false despite successful transfer!
    }

    // Returns false even though transfer succeeds
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return false; // Returns false despite successful transfer!
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return false; // Returns false despite successful approval!
    }
}
