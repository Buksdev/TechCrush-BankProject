// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {bankProject1} from "./BankProject1.sol";

//Task 2: ForLoop - manage multiple accounts using arrays and iterative logic
contract forLoop {

    //Reuse the accounts struct from bankProject1
    //Dynamic array to store multiple accounts
    bankProject1.accounts[] public accountsList;

    //Event to log each account added
    event AccountAdded(uint256 index, string name, address accountAddress);

    //Function that accepts multiple account details and uses a for loop
    //to programmatically add new accounts to the array
    function addMultipleAccounts(
        string[] memory _names,
        address[] memory _addresses
    ) public {
        //Check both arrays are the same length
        require(_names.length == _addresses.length, "Names and addresses length must match");
        require(_names.length > 0, "Must provide at least one account");

        //Use a for loop to go through each entry and add to accountsList
        for (uint256 i = 0; i < _names.length; i++) {
            //Create a new account struct in memory
            bankProject1.accounts memory newAccount = bankProject1.accounts({
                name: _names[i],
                accountBalance: 0,
                accountAddress: _addresses[i],
                accountStatus: true
            });

            //Push the new account into the dynamic array
            accountsList.push(newAccount);

            //Emit event for each account added
            emit AccountAdded(accountsList.length - 1, _names[i], _addresses[i]);
        }
    }

    //Get the total number of accounts in the array
    function getTotalAccounts() public view returns (uint256) {
        return accountsList.length;
    }

    //Get a single account by its index in the array
    function getAccountByIndex(uint256 _index) public view returns (bankProject1.accounts memory) {
        require(_index < accountsList.length, "Index out of bounds");
        return accountsList[_index];
    }

    //Get all accounts at once
    function getAllAccounts() public view returns (bankProject1.accounts[] memory) {
        return accountsList;
    }
}
