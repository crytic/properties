// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Pausable Token
 * @notice ERC20 token that can be paused by an admin
 * @dev Mimics tokens like BNB, ZIL that have pause functionality
 * @custom:example-tokens Binance Coin (BNB), Zilliqa (ZIL)
 * @custom:impact Admin can freeze all transfers at any time
 * @custom:risk Malicious or compromised admin can trap user funds
 * @custom:see https://github.com/d-xo/weird-erc20#pausable-tokens
 */
contract Pausable {
    string public name = "Pausable Token";
    string public symbol = "PAUSE";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public admin;
    bool public paused;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused();
    event Unpaused();

    modifier notPaused() {
        require(!paused, "Token is paused");
        _;
    }

    constructor() {
        admin = msg.sender;
        totalSupply = 1000000e18;
        balanceOf[msg.sender] = totalSupply;
    }

    function pause() external {
        require(msg.sender == admin, "Only admin");
        paused = true;
        emit Paused();
    }

    function unpause() external {
        require(msg.sender == admin, "Only admin");
        paused = false;
        emit Unpaused();
    }

    function transfer(address to, uint256 amount) public notPaused returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public notPaused returns (bool) {
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
