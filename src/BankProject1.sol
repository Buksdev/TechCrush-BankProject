// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

contract bankProject1 {

    //Custom error for low fee
    error FEEIsLow(uint256 _userFee);

    //Bank owner - set once at deployment, never changes
    address public immutable bankOwner;

    //Account creation fee = 1 ETH
    uint256 public constant FEE = 1e18;

    //Total fees collected from account creation
    uint public totalFee;

    //Total ETH held across all accounts
    uint256 public totalAmountInBank;

    //Account struct to store account details
    struct accounts {
        string name;
        uint256 accountBalance;
        address accountAddress;
        bool accountStatus;
        // bytes bvn;
    }

    //mapping key address to the value accounts
    mapping(address => accounts) public differentAccounts;

    //constructor - set bank owner
    constructor(address _owner) {
        bankOwner = _owner;
    }

    //Create modifier - only bank owner can call
    modifier onlyBankOwner(address _owner) {
        require(bankOwner == _owner, "Baba you are not the bank owner joor");
        _;
    }

    //1. bank can create different bank accounts
    //caller of this function is the account creator
    function createAccount(string memory _name) public payable onlyBankOwner(bankOwner) {
        //check fee is enough
        if (msg.value < FEE) {
            revert FEEIsLow(msg.value);
        }
        totalFee += msg.value;

        //User can't create account unless he is a bank owner
        require(msg.sender == bankOwner, "Go and meet the bank owner to create an account for you");
        differentAccounts[msg.sender] = accounts({
            name: _name,
            accountBalance: 0,
            accountAddress: msg.sender,
            accountStatus: true
        });
    }

    //2. user deposit money into different bank accounts
    //the function has to be payable because we want the contract to collect and store money
    //msg.value will be used
    function userDeposit() public payable {
        require(msg.value > 0, "You must send more than zero amount to the bank");
        //User will first pull out his bank account
        differentAccounts[msg.sender].accountBalance = differentAccounts[msg.sender].accountBalance + msg.value;
        totalAmountInBank += msg.value;
    }

    //3. owner of account can withdraw money from an account
    function userWithdraw(uint256 amount) public {
        //CEI - Check -> Effect -> Interaction
        //CHECK
        require(differentAccounts[msg.sender].accountBalance >= amount, "Insufficient balance");
        //EFFECT
        differentAccounts[msg.sender].accountBalance = differentAccounts[msg.sender].accountBalance - amount;
        totalAmountInBank -= amount;
        //INTERACTION
        (bool isWithdrawn, ) = payable(msg.sender).call{value: amount}("");
        require(isWithdrawn, "it is cancelled joor");
    }

    //4. owner A can transfer to owner B
    function transferMoney(address _to, uint256 amount) public {
        //CHECKS
        require(differentAccounts[msg.sender].accountBalance >= amount, "Insufficient funds");
        require(differentAccounts[msg.sender].accountStatus == true, "Account is not active");
        //EFFECTS
        differentAccounts[msg.sender].accountBalance -= amount;
        differentAccounts[_to].accountBalance += amount;
    }

    //5. close an account
    function closeAccount() public {
        //CHECKS
        require(differentAccounts[msg.sender].accountStatus == true, "Account already closed");
        //Get the balance of the account
        uint256 balance = differentAccounts[msg.sender].accountBalance;
        //Withdraw money from the contract for the user that wants to close an account
        userWithdraw(balance);
        //Delete the account from the mapping after withdrawing the balance
        delete differentAccounts[msg.sender];
    }
}
