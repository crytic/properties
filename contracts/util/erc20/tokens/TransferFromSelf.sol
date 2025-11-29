// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title TransferFrom Self Token
 * @notice ERC20 token that doesn't decrease allowance when sender transfers their own tokens
 * @dev Mimics tokens like DSToken where transferFrom doesn't use allowance if from == msg.sender
 * @custom:example-tokens DSToken (DAI), WETH9
 * @custom:impact Allowance is not decreased when owner transfers their own tokens via transferFrom
 * @custom:see https://github.com/d-xo/weird-erc20#no-allowance-decrease-when-transferring-own-tokens
 */
contract TransferFromSelf {
    string public name = "TransferFrom Self Token";
    string public symbol = "TFS";
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

        // Only check and decrease allowance if sender is not the owner
        if (from != msg.sender) {
            require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
