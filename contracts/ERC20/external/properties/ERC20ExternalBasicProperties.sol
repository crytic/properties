pragma solidity ^0.8.0;

import {CryticERC20ExternalTestBase} from "../util/ERC20ExternalTestBase.sol";

abstract contract CryticERC20ExternalBasicProperties is
    CryticERC20ExternalTestBase
{
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Total supply should change only by means of mint or burn
    function test_ERC20external_constantSupply() public virtual {
        require(!token.isMintableOrBurnable());
        assertEq(
            token.initialSupply(),
            token.totalSupply(),
            "Token supply was modified"
        );
    }

    // User balance must not exceed total supply
    function test_ERC20external_userBalanceNotHigherThanSupply() public {
        assertLte(
            token.balanceOf(msg.sender),
            token.totalSupply(),
            "User balance higher than total supply"
        );
    }

    // Sum of users balance must not exceed total supply
    function test_ERC20external_userBalancesLessThanTotalSupply() public {
        uint256 sumBalances = token.balanceOf(address(this)) +
            token.balanceOf(USER1) +
            token.balanceOf(USER2) +
            token.balanceOf(USER3);
        assertLte(
            sumBalances,
            token.totalSupply(),
            "Sum of user balances are greater than total supply"
        );
    }

    // Address zero should have zero balance
    function test_ERC20external_zeroAddressBalance() public {
        assertEq(
            token.balanceOf(address(0)),
            0,
            "Address zero balance not equal to zero"
        );
    }

    // Transfers to zero address should not be allowed
    function test_ERC20external_transferToZeroAddress() public {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        bool r = token.transfer(address(0), balance);
        assertWithMsg(r == false, "Successful transfer to address zero");
    }

    // Transfers to zero address should not be allowed
    function test_ERC20external_transferFromToZeroAddress(
        uint256 value
    ) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > 0);
        uint256 maxValue = balance_sender >= allowance
            ? allowance
            : balance_sender;

        bool r = token.transferFrom(
            msg.sender,
            address(0),
            value % (maxValue + 1)
        );
        assertWithMsg(r == false, "Successful transferFrom to address zero");
    }

    // Self transfers should not break accounting
    function test_ERC20external_selfTransferFrom(uint256 value) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > 0);
        uint256 maxValue = balance_sender >= allowance
            ? allowance
            : balance_sender;

        bool r = token.transferFrom(
            msg.sender,
            msg.sender,
            value % (maxValue + 1)
        );
        assertWithMsg(r == true, "Failed self transferFrom");
        assertEq(
            balance_sender,
            token.balanceOf(msg.sender),
            "Self transferFrom breaks accounting"
        );
    }

    // Self transfers should not break accounting
    function test_ERC20external_selfTransfer(uint256 value) public {
        uint256 balance_sender = token.balanceOf(address(this));
        require(balance_sender > 0);

        bool r = token.transfer(address(this), value % (balance_sender + 1));
        assertWithMsg(r == true, "Failed self transfer");
        assertEq(
            balance_sender,
            token.balanceOf(address(this)),
            "Self transfer breaks accounting"
        );
    }

    // Transfers for more than available balance should not be allowed
    function test_ERC20external_transferFromMoreThanBalance(
        address target
    ) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > balance_sender);

        bool r = token.transferFrom(msg.sender, target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transferFrom for more than account balance"
        );
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender,
            "TransferFrom for more than balance modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "TransferFrom for more than balance modified target balance"
        );
    }

    // Transfers for more than available balance should not be allowed
    function test_ERC20external_transferMoreThanBalance(address target) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 0);

        bool r = token.transfer(target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transfer for more than account balance"
        );
        assertEq(
            token.balanceOf(address(this)),
            balance_sender,
            "Transfer for more than balance modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Transfer for more than balance modified target balance"
        );
    }

    // Zero amount transfers should not break accounting
    function test_ERC20external_transferZeroAmount(address target) public {
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 0);

        bool r = token.transfer(target, 0);
        assertWithMsg(r == true, "Zero amount transfer failed");
        assertEq(
            token.balanceOf(address(this)),
            balance_sender,
            "Zero amount transfer modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Zero amount transfer modified target balance"
        );
    }

    // Zero amount transfers should not break accounting
    function test_ERC20external_transferFromZeroAmount(address target) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance > 0);

        bool r = token.transferFrom(msg.sender, target, 0);
        assertWithMsg(r == true, "Zero amount transferFrom failed");
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender,
            "Zero amount transferFrom modified source balance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "Zero amount transferFrom modified target balance"
        );
    }

    // Transfers should update accounting correctly
    function test_ERC20external_transfer(
        address target,
        uint256 amount
    ) public {
        require(target != address(this));
        uint256 balance_sender = token.balanceOf(address(this));
        uint256 balance_receiver = token.balanceOf(target);
        require(balance_sender > 2);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = token.transfer(target, transfer_value);
        assertWithMsg(r == true, "transfer failed");
        assertEq(
            token.balanceOf(address(this)),
            balance_sender - transfer_value,
            "Wrong source balance after transfer"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transfer"
        );
    }

    // Transfers should update accounting correctly
    function test_ERC20external_transferFrom(
        address target,
        uint256 amount
    ) public {
        require(target != address(this));
        require(target != msg.sender);
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 2 && allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = token.transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transfer failed");
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender - transfer_value,
            "Wrong source balance after transferFrom"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transferFrom"
        );
    }

    // Approve should set correct allowances
    function test_ERC20external_setAllowance(
        address target,
        uint256 amount
    ) public {
        bool r = token.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );
    }

    // Approve should set correct allowances
    function test_ERC20external_setAllowanceTwice(
        address target,
        uint256 amount
    ) public {
        bool r = token.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );

        r = token.approve(target, amount / 2);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            token.allowance(address(this), target),
            amount / 2,
            "Allowance not set correctly"
        );
    }

    // TransferFrom should decrease allowance
    function test_ERC20external_spendAllowanceAfterTransfer(
        address target,
        uint256 amount
    ) public {
        require(target != address(this) && target != address(0));
        require(target != msg.sender);
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 current_allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = token.transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transferFrom failed");

        // Some implementations take an allowance of 2**256-1 as infinite, and therefore don't update
        if (current_allowance != type(uint256).max) {
            assertEq(
                token.allowance(msg.sender, address(this)),
                current_allowance - transfer_value,
                "Allowance not updated correctly"
            );
        }
    }
}
