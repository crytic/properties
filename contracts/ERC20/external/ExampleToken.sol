pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExampleToken is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Example token", "EXT") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract ExampleTokenNonCompliant is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Example token", "EXT") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function approve(
        address,
        uint256
    ) public virtual override(ERC20) returns (bool) {
        // do nothing
        return true;
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
