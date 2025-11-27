// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title BlockList Token
 * @notice ERC20 token with admin-controlled address blocklist
 * @dev Mimics tokens like USDC, USDT that can block addresses
 * @custom:example-tokens USDC, USDT
 * @custom:impact Admin can freeze funds in contracts at any time
 * @custom:risk Regulatory action, compromised admin, or extortion
 * @custom:see https://github.com/d-xo/weird-erc20#tokens-with-blocklists
 */
contract BlockList {
    string public name = "BlockList Token";
    string public symbol = "BLOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public admin;
    mapping(address => bool) public isBlocked;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AddressBlocked(address indexed account);
    event AddressUnblocked(address indexed account);

    modifier notBlocked(address account) {
        require(!isBlocked[account], "Address is blocked");
        _;
    }

    constructor() {
        admin = msg.sender;
        totalSupply = 1000000e18;
        balanceOf[msg.sender] = totalSupply;
    }

    function blockAddress(address account) external {
        require(msg.sender == admin, "Only admin");
        isBlocked[account] = true;
        emit AddressBlocked(account);
    }

    function unblockAddress(address account) external {
        require(msg.sender == admin, "Only admin");
        isBlocked[account] = false;
        emit AddressUnblocked(account);
    }

    function transfer(address to, uint256 amount)
        public
        notBlocked(msg.sender)
        notBlocked(to)
        returns (bool)
    {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        notBlocked(from)
        notBlocked(to)
        returns (bool)
    {
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
