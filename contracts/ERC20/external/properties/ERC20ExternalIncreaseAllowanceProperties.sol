pragma solidity ^0.8.0;

import "../util/ERC20ExternalTestBase.sol";

abstract contract CryticERC20ExternalIncreaseAllowanceProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Allowance should be modified correctly via increase/decrease
    function test_ERC20external_setAndIncreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 increaseAmount
    ) public {
        bool r = token.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = token.increaseAllowance(target, increaseAmount);
        assertWithMsg(r == true, "Failed to increase allowance");
        assertEq(
            token.allowance(address(this), target),
            initialAmount + increaseAmount,
            "Allowance not increased correctly"
        );
    }

    // Allowance should be modified correctly via increase/decrease
    function test_ERC20external_setAndDecreaseAllowance(
        address target,
        uint256 initialAmount,
        uint256 decreaseAmount
    ) public {
        bool r = token.approve(target, initialAmount);
        assertWithMsg(r == true, "Failed to set initial allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            initialAmount,
            "Allowance not set correctly"
        );

        r = token.decreaseAllowance(target, decreaseAmount);
        assertWithMsg(r == true, "Failed to decrease allowance");
        assertEq(
            token.allowance(address(this), target),
            initialAmount - decreaseAmount,
            "Allowance not decreased correctly"
        );
    }
}
