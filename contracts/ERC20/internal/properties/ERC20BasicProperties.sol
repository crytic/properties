pragma solidity ^0.8.13;

import "../util/ERC20TestBase.sol";

abstract contract CryticERC20BasicProperties is CryticERC20Base {
    constructor() {}

    ////////////////////////////////////////
    // Properties

    // Total supply should change only by means of mint or burn
    function test_ERC20_constantSupply() public virtual {
        require(!isMintableOrBurnable);
        assertEq(initialSupply, totalSupply(), "Token supply was modified");
    }

    // User balance must not exceed total supply
    function test_ERC20_userBalanceNotHigherThanSupply() public {
        assertLte(
            balanceOf(msg.sender),
            totalSupply(),
            "User balance higher than total supply"
        );
    }

    // Sum of users balance must not exceed total supply
    function test_ERC20_usersBalancesNotHigherThanSupply() public {
        uint256 balance = balanceOf(USER1) +
            balanceOf(USER2) +
            balanceOf(USER3);
        assertLte(
            balance,
            totalSupply(),
            "Sum of user balances higher than total supply"
        );
    }

    // Address zero should have zero balance
    function test_ERC20_zeroAddressBalance() public {
        assertEq(
            balanceOf(address(0)),
            0,
            "Address zero balance not equal to zero"
        );
    }

    // Transfers to zero address should not be allowed
    function test_ERC20_transferToZeroAddress() public {
        uint256 balance = balanceOf(address(this));
        require(balance > 0);

        bool r = transfer(address(0), balance);
        assertWithMsg(r == false, "Successful transfer to address zero");
    }

    // Transfers to zero address should not be allowed
    function test_ERC20_transferFromToZeroAddress(uint256 value) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > 0);
        uint256 maxValue = balance_sender >= current_allowance
            ? current_allowance
            : balance_sender;

        bool r = transferFrom(msg.sender, address(0), value % (maxValue + 1));
        assertWithMsg(r == false, "Successful transferFrom to address zero");
    }

    // Self transfers should not break accounting
    function test_ERC20_selfTransferFrom(uint256 value) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > 0);
        uint256 maxValue = balance_sender >= current_allowance
            ? current_allowance
            : balance_sender;

        bool r = transferFrom(msg.sender, msg.sender, value % (maxValue + 1));
        assertWithMsg(r == true, "Failed self transferFrom");
        assertEq(
            balance_sender,
            balanceOf(msg.sender),
            "Self transferFrom breaks accounting"
        );
    }

    // Self transfers should not break accounting
    function test_ERC20_selfTransfer(uint256 value) public {
        uint256 balance_sender = balanceOf(address(this));
        require(balance_sender > 0);

        bool r = this.transfer(address(this), value % (balance_sender + 1));
        assertWithMsg(r == true, "Failed self transfer");
        assertEq(
            balance_sender,
            balanceOf(address(this)),
            "Self transfer breaks accounting"
        );
    }

    // Transfers for more than available balance should not be allowed
    function test_ERC20_transferFromMoreThanBalance(address target) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);

        bool r = transferFrom(msg.sender, target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transferFrom for more than account balance"
        );
        assertEq(
            balanceOf(msg.sender),
            balance_sender,
            "TransferFrom for more than balance modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "TransferFrom for more than balance modified target balance"
        );
    }

    // Transfers for more than available balance should not be allowed
    function test_ERC20_transferMoreThanBalance(address target) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 0);

        bool r = this.transfer(target, balance_sender + 1);
        assertWithMsg(
            r == false,
            "Successful transfer for more than account balance"
        );
        assertEq(
            balanceOf(address(this)),
            balance_sender,
            "Transfer for more than balance modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Transfer for more than balance modified target balance"
        );
    }

    // Zero amount transfers should not break accounting
    function test_ERC20_transferZeroAmount(address target) public {
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 0);

        bool r = transfer(target, 0);
        assertWithMsg(r == true, "Zero amount transfer failed");
        assertEq(
            balanceOf(address(this)),
            balance_sender,
            "Zero amount transfer modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Zero amount transfer modified target balance"
        );
    }

    // Zero amount transfers should not break accounting
    function test_ERC20_transferFromZeroAmount(address target) public {
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > 0);

        bool r = transferFrom(msg.sender, target, 0);
        assertWithMsg(r == true, "Zero amount transferFrom failed");
        assertEq(
            balanceOf(msg.sender),
            balance_sender,
            "Zero amount transferFrom modified source balance"
        );
        assertEq(
            balanceOf(target),
            balance_receiver,
            "Zero amount transferFrom modified target balance"
        );
    }

    // Transfers should update accounting correctly
    function test_ERC20_transfer(address target, uint256 amount) public {
        require(target != address(this));
        uint256 balance_sender = balanceOf(address(this));
        uint256 balance_receiver = balanceOf(target);
        require(balance_sender > 2);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = this.transfer(target, transfer_value);
        assertWithMsg(r == true, "transfer failed");
        assertEq(
            balanceOf(address(this)),
            balance_sender - transfer_value,
            "Wrong source balance after transfer"
        );
        assertEq(
            balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transfer"
        );
    }

    // Transfers should update accounting correctly
    function test_ERC20_transferFrom(address target, uint256 amount) public {
        require(target != address(this));
        require(target != msg.sender);
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 balance_receiver = balanceOf(target);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 2 && current_allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transferFrom failed");
        assertEq(
            balanceOf(msg.sender),
            balance_sender - transfer_value,
            "Wrong source balance after transferFrom"
        );
        assertEq(
            balanceOf(target),
            balance_receiver + transfer_value,
            "Wrong target balance after transferFrom"
        );
    }

    // Approve should set correct allowances
    function test_ERC20_setAllowance(address target, uint256 amount) public {
        bool r = this.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );
    }

    // Approve should set correct allowances
    function test_ERC20_setAllowanceTwice(
        address target,
        uint256 amount
    ) public {
        bool r = this.approve(target, amount);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            allowance(address(this), target),
            amount,
            "Allowance not set correctly"
        );

        r = this.approve(target, amount / 2);
        assertWithMsg(r == true, "Failed to set allowance via approve");
        assertEq(
            allowance(address(this), target),
            amount / 2,
            "Allowance not set correctly"
        );
    }

    // TransferFrom should decrease allowance
    function test_ERC20_spendAllowanceAfterTransfer(
        address target,
        uint256 amount
    ) public {
        require(target != address(this) && target != address(0));
        require(target != msg.sender);
        uint256 balance_sender = balanceOf(msg.sender);
        uint256 current_allowance = allowance(msg.sender, address(this));
        require(balance_sender > 0 && current_allowance > balance_sender);
        uint256 transfer_value = (amount % balance_sender) + 1;

        bool r = this.transferFrom(msg.sender, target, transfer_value);
        assertWithMsg(r == true, "transferFrom failed");

        // Some implementations take an allowance of 2**256-1 as infinite, and therefore don't update
        if (current_allowance != type(uint256).max) {
            assertEq(
                allowance(msg.sender, address(this)),
                current_allowance - transfer_value,
                "Allowance not updated correctly"
            );
        }
    }

    // TransferFrom for more than allowance should not be allowed
    function test_ERC20_transferFromMoreThanAllowance(
        address target
    ) public {
        uint256 balance_sender = token.balanceOf(msg.sender);
        uint256 balance_receiver = token.balanceOf(target);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(balance_sender > 0 && allowance < balance_sender);

        bool r = token.transferFrom(msg.sender, target, allowance + 1);
        assertWithMsg(
            r == false,
            "Successful transferFrom for more than allowance"
        );
        assertEq(
            token.balanceOf(msg.sender),
            balance_sender,
            "TransferFrom for more than amount approved source allowance"
        );
        assertEq(
            token.balanceOf(target),
            balance_receiver,
            "TransferFrom for more than amount approved target allowance"
        );
    }
}
