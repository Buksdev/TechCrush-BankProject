// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {bankProject1} from "../src/BankProject1.sol";
import {forLoop} from "../src/ForLoop.sol";

contract bankProject1Test is Test {

    bankProject1 bank;
    forLoop      forLoopContract;

    //Test actors
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    //Give everyone ETH before each test
    function setUp() public {
        bank             = new bankProject1(owner);
        forLoopContract  = new forLoop();

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob,   100 ether);
    }

    // -----------------------------------------------------------------------
    // Deployment tests
    // -----------------------------------------------------------------------

    function test_bankOwnerIsSetCorrectly() public view {
        assertEq(bank.bankOwner(), owner);
    }

    function test_feeIsOneEther() public view {
        assertEq(bank.FEE(), 1e18);
    }

    function test_totalFeeStartsAtZero() public view {
        assertEq(bank.totalFee(), 0);
    }

    function test_totalAmountInBankStartsAtZero() public view {
        assertEq(bank.totalAmountInBank(), 0);
    }

    // -----------------------------------------------------------------------
    // createAccount tests
    // -----------------------------------------------------------------------

    function test_createAccount_ownerCanCreateAccount() public {
        vm.prank(owner);
        bank.createAccount{value: 1 ether}("Owner Account");

        //Pull out the account and check values
        (string memory name, uint256 balance, address addr, bool status) = bank.differentAccounts(owner);
        assertEq(name, "Owner Account");
        assertEq(balance, 0);
        assertEq(addr, owner);
        assertTrue(status);
    }

    function test_createAccount_totalFeeIncreasesAfterCreation() public {
        vm.prank(owner);
        bank.createAccount{value: 1 ether}("Owner Account");

        assertEq(bank.totalFee(), 1 ether);
    }

    function test_createAccount_revertsWithFEEIsLow_whenFeeTooLow() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(bankProject1.FEEIsLow.selector, 0.5 ether));
        bank.createAccount{value: 0.5 ether}("Cheap Account");
    }

    function test_createAccount_revertsWhenCalledByNonOwner() public {
        vm.prank(alice);
        vm.expectRevert("Baba you are not the bank owner joor");
        bank.createAccount{value: 1 ether}("Alice");
    }

    // -----------------------------------------------------------------------
    // userDeposit tests
    // -----------------------------------------------------------------------

    //Helper: create an account for owner before deposit tests
    modifier withOwnerAccount() {
        vm.prank(owner);
        bank.createAccount{value: 1 ether}("Owner Account");
        _;
    }

    function test_userDeposit_increasesAccountBalance() public withOwnerAccount {
        vm.prank(owner);
        bank.userDeposit{value: 1 ether}();

        (, uint256 balance,,) = bank.differentAccounts(owner);
        assertEq(balance, 1 ether);
    }

    function test_userDeposit_increasesTotalAmountInBank() public withOwnerAccount {
        vm.prank(owner);
        bank.userDeposit{value: 1 ether}();

        assertEq(bank.totalAmountInBank(), 1 ether);
    }

    function test_userDeposit_multipleDepositsAccumulate() public withOwnerAccount {
        vm.startPrank(owner);
        bank.userDeposit{value: 1 ether}();
        bank.userDeposit{value: 1 ether}();
        vm.stopPrank();

        (, uint256 balance,,) = bank.differentAccounts(owner);
        assertEq(balance, 2 ether);
    }

    function test_userDeposit_revertsOnZeroValue() public withOwnerAccount {
        vm.prank(owner);
        vm.expectRevert("You must send more than zero amount to the bank");
        bank.userDeposit{value: 0}();
    }

    // -----------------------------------------------------------------------
    // userWithdraw tests
    // -----------------------------------------------------------------------

    //Helper: create account and deposit 2 ETH
    modifier withOwnerFunded() {
        vm.prank(owner);
        bank.createAccount{value: 1 ether}("Owner Account");
        vm.prank(owner);
        bank.userDeposit{value: 2 ether}();
        _;
    }

    function test_userWithdraw_decreasesAccountBalance() public withOwnerFunded {
        vm.prank(owner);
        bank.userWithdraw(1 ether);

        (, uint256 balance,,) = bank.differentAccounts(owner);
        assertEq(balance, 1 ether);
    }

    function test_userWithdraw_decreasesTotalAmountInBank() public withOwnerFunded {
        vm.prank(owner);
        bank.userWithdraw(1 ether);

        assertEq(bank.totalAmountInBank(), 1 ether);
    }

    function test_userWithdraw_sendsEtherBackToCaller() public withOwnerFunded {
        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        bank.userWithdraw(1 ether);

        assertEq(owner.balance, balanceBefore + 1 ether);
    }

    function test_userWithdraw_revertsOnInsufficientBalance() public withOwnerFunded {
        vm.prank(owner);
        vm.expectRevert("Insufficient balance");
        bank.userWithdraw(10 ether);
    }

    // -----------------------------------------------------------------------
    // transferMoney tests
    // -----------------------------------------------------------------------

    modifier withOwnerAndAlice() {
        //Create and fund owner
        vm.prank(owner);
        bank.createAccount{value: 1 ether}("Owner Account");
        vm.prank(owner);
        bank.userDeposit{value: 2 ether}();
        _;
    }

    function test_transferMoney_movesFundsToRecipient() public withOwnerAndAlice {
        vm.prank(owner);
        bank.transferMoney(alice, 1 ether);

        (, uint256 ownerBalance,,) = bank.differentAccounts(owner);
        (, uint256 aliceBalance,,) = bank.differentAccounts(alice);

        assertEq(ownerBalance, 1 ether);
        assertEq(aliceBalance, 1 ether);
    }

    function test_transferMoney_totalAmountInBankDoesNotChange() public withOwnerAndAlice {
        uint256 before = bank.totalAmountInBank();

        vm.prank(owner);
        bank.transferMoney(alice, 1 ether);

        assertEq(bank.totalAmountInBank(), before);
    }

    function test_transferMoney_revertsOnInsufficientFunds() public withOwnerAndAlice {
        vm.prank(owner);
        vm.expectRevert("Insufficient funds");
        bank.transferMoney(alice, 50 ether);
    }

    function test_transferMoney_revertsIfAccountNotActive() public {
        //owner has no account so accountStatus is false
        vm.prank(owner);
        vm.expectRevert("Account is not active");
        bank.transferMoney(alice, 1 ether);
    }

    // -----------------------------------------------------------------------
    // closeAccount tests
    // -----------------------------------------------------------------------

    function test_closeAccount_refundsBalanceToCaller() public withOwnerFunded {
        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        bank.closeAccount();

        //2 ETH was deposited - should all come back
        assertEq(owner.balance, balanceBefore + 2 ether);
    }

    function test_closeAccount_deletesAccountFromMapping() public withOwnerFunded {
        vm.prank(owner);
        bank.closeAccount();

        //After delete, all fields return zero values
        (string memory name, uint256 balance, address addr, bool status) = bank.differentAccounts(owner);
        assertEq(name, "");
        assertEq(balance, 0);
        assertEq(addr, address(0));
        assertFalse(status);
    }

    function test_closeAccount_revertsIfAlreadyClosed() public withOwnerFunded {
        vm.startPrank(owner);
        bank.closeAccount();

        vm.expectRevert("Account already closed");
        bank.closeAccount();
        vm.stopPrank();
    }

    // -----------------------------------------------------------------------
    // ForLoop tests
    // -----------------------------------------------------------------------

    function test_forLoop_startsWithEmptyArray() public view {
        assertEq(forLoopContract.getTotalAccounts(), 0);
    }

    function test_forLoop_addsMultipleAccountsCorrectly() public {
        string[]  memory names = new string[](3);
        address[] memory addrs = new address[](3);

        names[0] = "Alice"; addrs[0] = alice;
        names[1] = "Bob";   addrs[1] = bob;
        names[2] = "Carol"; addrs[2] = makeAddr("carol");

        forLoopContract.addMultipleAccounts(names, addrs);

        assertEq(forLoopContract.getTotalAccounts(), 3);
    }

    function test_forLoop_storesNameAndAddressCorrectly() public {
        string[]  memory names = new string[](2);
        address[] memory addrs = new address[](2);
        names[0] = "Alice"; addrs[0] = alice;
        names[1] = "Bob";   addrs[1] = bob;

        forLoopContract.addMultipleAccounts(names, addrs);

        bankProject1.accounts memory a = forLoopContract.getAccountByIndex(0);
        assertEq(a.name, "Alice");
        assertEq(a.accountAddress, alice);

        bankProject1.accounts memory b = forLoopContract.getAccountByIndex(1);
        assertEq(b.name, "Bob");
        assertEq(b.accountAddress, bob);
    }

    function test_forLoop_newAccountStatusIsTrue() public {
        string[]  memory names = new string[](1);
        address[] memory addrs = new address[](1);
        names[0] = "Alice"; addrs[0] = alice;

        forLoopContract.addMultipleAccounts(names, addrs);

        bankProject1.accounts memory a = forLoopContract.getAccountByIndex(0);
        assertTrue(a.accountStatus);
    }

    function test_forLoop_newAccountBalanceIsZero() public {
        string[]  memory names = new string[](1);
        address[] memory addrs = new address[](1);
        names[0] = "Alice"; addrs[0] = alice;

        forLoopContract.addMultipleAccounts(names, addrs);

        bankProject1.accounts memory a = forLoopContract.getAccountByIndex(0);
        assertEq(a.accountBalance, 0);
    }

    function test_forLoop_accumulatesAcrossMultipleCalls() public {
        string[]  memory names1 = new string[](1);
        address[] memory addrs1 = new address[](1);
        names1[0] = "Alice"; addrs1[0] = alice;
        forLoopContract.addMultipleAccounts(names1, addrs1);

        string[]  memory names2 = new string[](2);
        address[] memory addrs2 = new address[](2);
        names2[0] = "Bob";   addrs2[0] = bob;
        names2[1] = "Carol"; addrs2[1] = makeAddr("carol");
        forLoopContract.addMultipleAccounts(names2, addrs2);

        assertEq(forLoopContract.getTotalAccounts(), 3);
    }

    function test_forLoop_emitsAccountAddedEvent() public {
        string[]  memory names = new string[](1);
        address[] memory addrs = new address[](1);
        names[0] = "Alice"; addrs[0] = alice;

        vm.expectEmit(false, false, false, true);
        emit forLoop.AccountAdded(0, "Alice", alice);

        forLoopContract.addMultipleAccounts(names, addrs);
    }

    function test_forLoop_revertsOnLengthMismatch() public {
        string[]  memory names = new string[](2);
        address[] memory addrs = new address[](1);
        names[0] = "Alice"; names[1] = "Bob";
        addrs[0] = alice;

        vm.expectRevert("Names and addresses length must match");
        forLoopContract.addMultipleAccounts(names, addrs);
    }

    function test_forLoop_revertsOnEmptyInput() public {
        string[]  memory names = new string[](0);
        address[] memory addrs = new address[](0);

        vm.expectRevert("Must provide at least one account");
        forLoopContract.addMultipleAccounts(names, addrs);
    }

    function test_forLoop_getAllAccountsReturnsAll() public {
        string[]  memory names = new string[](2);
        address[] memory addrs = new address[](2);
        names[0] = "Alice"; addrs[0] = alice;
        names[1] = "Bob";   addrs[1] = bob;
        forLoopContract.addMultipleAccounts(names, addrs);

        bankProject1.accounts[] memory all = forLoopContract.getAllAccounts();
        assertEq(all.length, 2);
        assertEq(all[0].name, "Alice");
        assertEq(all[1].name, "Bob");
    }

    function test_forLoop_getAccountByIndexRevertsOutOfBounds() public {
        vm.expectRevert("Index out of bounds");
        forLoopContract.getAccountByIndex(99);
    }
}
