// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Approval Race Protection Token
 * @notice ERC20 token that prevents changing non-zero allowances to non-zero values
 * @dev Mimics tokens like USDT, KNC that protect against approval race conditions
 * @custom:example-tokens Tether (USDT), Kyber Network (KNC)
 * @custom:impact Must set allowance to zero before changing to a new non-zero value
 * @custom:see https://github.com/d-xo/weird-erc20#approval-race-protections
 */
contract ApprovalRaceProtection {
    string public name = "Approval Race Protection Token";
    string public symbol = "RACE";
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
        // Cannot change non-zero allowance to a different non-zero value
        // Must first set to zero, then set to new value
        require(
            allowance[msg.sender][spender] == 0 || amount == 0,
            "Must reset allowance to zero first"
        );
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
