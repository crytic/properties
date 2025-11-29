// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/**
 * @title Transfer Max Token
 * @notice ERC20 token that transfers full balance when amount is type(uint256).max
 * @dev Mimics tokens like cUSDCv3 that treat max uint as "transfer all"
 * @custom:example-tokens Compound v3 USDC (cUSDCv3)
 * @custom:impact Amount of type(uint256).max transfers entire balance instead of literal value
 * @custom:see https://github.com/d-xo/weird-erc20#transfer-of-uint256max
 */
contract TransferMax {
    string public name = "Transfer Max Token";
    string public symbol = "TMAX";
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
        // If amount is max uint, transfer entire balance
        uint256 actualAmount = amount == type(uint256).max ? balanceOf[msg.sender] : amount;

        require(balanceOf[msg.sender] >= actualAmount, "Insufficient balance");
        balanceOf[msg.sender] -= actualAmount;
        balanceOf[to] += actualAmount;
        emit Transfer(msg.sender, to, actualAmount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        // If amount is max uint, transfer entire balance
        uint256 actualAmount = amount == type(uint256).max ? balanceOf[from] : amount;

        require(balanceOf[from] >= actualAmount, "Insufficient balance");
        require(allowance[from][msg.sender] >= actualAmount, "Insufficient allowance");
        balanceOf[from] -= actualAmount;
        balanceOf[to] += actualAmount;
        allowance[from][msg.sender] -= actualAmount;
        emit Transfer(from, to, actualAmount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}
