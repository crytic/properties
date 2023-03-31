pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

abstract contract CryticERC20IncreaseAllowanceProperties is CryticERC20Base {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Allowance should be modified correctly via increase/decrease
    function test_ERC20_setAndIncreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 increaseAmount
    ) public {
        bool r = this.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = this.increaseAllowance(target, increaseAmount);
        assertWithMsg(r == true, "Failed to increase allowance");
        assertEq(
            allowance(address(this), target),
            initialAmount + increaseAmount,
            "Allowance not increased correctly"
        );
    }

    // Allowance should be modified correctly via increase/decrease
    function test_ERC20_setAndDecreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 decreaseAmount
    ) public {
        bool r = this.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = this.decreaseAllowance(target, decreaseAmount);
        assertWithMsg(r == true, "Failed to decrease allowance");
        assertEq(
            allowance(address(this), target),
            initialAmount - decreaseAmount,
            "Allowance not decreased correctly"
        );
    }
}
