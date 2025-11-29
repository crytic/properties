// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title No Revert Token
 * @notice ERC20 token that returns false instead of reverting on failure
 * @dev Mimics tokens like ZRX, EURS that don't revert on failure
 * @custom:example-tokens 0x Protocol Token (ZRX), EURS
 * @custom:impact Requires explicit check of return value, easily overlooked
 * @custom:see https://github.com/d-xo/weird-erc20#no-revert-on-failure
 */
contract NoRevert {
    string public name = "No Revert Token";
    string public symbol = "NOREV";
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

    // Returns false instead of reverting on insufficient balance
    function transfer(address to, uint256 amount) public returns (bool) {
        if (balanceOf[msg.sender] < amount) {
            return false; // No revert!
        }
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Returns false instead of reverting on insufficient balance/allowance
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (balanceOf[from] < amount || allowance[from][msg.sender] < amount) {
            return false; // No revert!
        }
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
