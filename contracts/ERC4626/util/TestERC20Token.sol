pragma solidity ^0.8.0;

contract TestERC20Token {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint256 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        uint256 spenderAllowance = allowance[from][msg.sender];
        if (spenderAllowance != type(uint256).max) {
            allowance[from][msg.sender] = spenderAllowance - amount;
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public {
        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) public {
        totalSupply -= amount;
        balanceOf[from] -= amount;

        emit Transfer(from, address(0), amount);
    }

    function forceApproval(
        address account,
        address spender,
        uint256 amount
    ) public {
        allowance[account][spender] = amount;
        emit Approval(account, spender, amount);
    }
}
