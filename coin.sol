pragma solidity ^0.4.13;

contract SHIBORKcoin{
    string public constant name = 'SHIBORKcoin';
    string public constant symbol = 'SBN';

    //uint256 represent that the coin can hold 32-byte
    uint256 public rate;
    //total is the total coins that have been minted up until now
    //it can contain the number of coins of 2^256
    uint256 public total;
    //the owner allow to mint or burn new coin (as the coin is more, the value is less, viceversa)
    //minting coin is to make new coins, as burning coin is to delete some coins
    address public owner;

    //hashing between the coin and the one who owns it
    mapping (address => uint256) public balances;
    //hashing between the allowed value of money to be used by the other address
    //to check the allowed value in the interface, the first address is the owner of the value
    //and the second address is the spender
    mapping (address => mapping (address => uint256)) public allowed;

    //broadcast the entire blockchain that someone event happened with the particular parameters
    event Burn(address indexed _from, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event OwnerUpdate(address indexed _oldOwner, address indexed _owner);
    event RateUpdate (uint256 _oldRate, uint256 _rate);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
    event Buy (address indexed _from, uint256 _value, uint256 _rate);
    event Sell (address indexed _from, uint256 _value, uint256 _rate);

    function SHIBORKcoin(uint256 _value, uint256 _rate){
        owner = msg.sender;
        total = _value;
        //give the value to the address of the owner
        balances[msg.sender] = _value;
        rate = _rate;
    }

    //create new coin, giving the some value of coin to the address
    function mint(address _to, uint256 _value) returns (bool success){
        //revert will do nothing and return false
        //in case someone who is not owner, it can't be minted
        if (msg.sender != owner) revert();
        //in case of the invalid address, the transaction will fail
        if (_to == 0x0) revert();

        //increase the balance of the minter
        balances[_to] += _value;
        total += _value;

        return true;
    }

    //in some implementation, the burn is called (in a smaller ammount) whenever
    //the mint is called to avoid inflation
    function burn(address _from, uint256 _value) returns (bool success){
        //to check whether the owner has enough value
        if (balances[_from] < _value) revert();

        balances[msg.sender] -= _value;
        total -= _value;
        Burn(msg.sender, _value);

        return true;
    }

    //the returns line is for checking whether the operation / function succeed or not
    function transfer(address _to, uint256 _value) returns (bool success){
        if (_to == 0x0) revert();
        if (balances[msg.sender] < _value) revert();
        //to avoid overflow, whether the balance of the receiver is not less after the coin is transferred
        if (balances[_to] + _value < balances[_to]) revert();

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);

        return true;
    }


    //giving the rights of the owner to someone or configure the owner
    function configOwner(address _owner) returns (bool success) {
        if (msg.sender != owner) revert();
        if (_owner == 0x0) revert();

        var oldOwner = owner;
        var oldBalance = balances[owner];
        //transfer the balance from the old account to the new ones
        balances[owner] -= oldBalance;
        balances[_owner] += oldBalance;
        //changing the owner or granting the rights to other address
        owner = _owner;
        OwnerUpdate(oldOwner, _owner);

        return true;
    }


    //configure or change the rate of the coin
    function configRate (uint256 _rate) returns (bool success) {
        if (msg.sender != owner) revert();

        var oldRate = rate;
        rate = _rate;
        RateUpdate(oldRate, _rate);

        return true;
    }

    //to return the amount of the coin available, to be utilised in control of the inflation
    function totalSupply() constant returns (uint256 supply) {
        return total;
    }

    //checking the balances of a particular address
    function balancesOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    //
    function approved (address _spender, uint256 _value) returns (bool success) {
        if (_spender == 0x0) revert();

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function burnFrom (address _from, uint256 _value) returns (bool success) {
        if (_from == 0x0) revert();
        if (balances[_from] < _value) revert();
        //checking whether the coin allowed to be used by other address is more or not
        if (allowed[_from][msg.sender] < _value) revert();

        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        total -= _value;
        Burn(msg.sender, _value);

        return true;
    }

   function transferFrom (address _from, address _to, uint256 _value) returns (bool success) {
        if (_from == 0x0) revert();
        if (_to == 0x0) revert();
        if (balances[_from] < _value) revert();
        if (allowed[_from][msg.sender] < _value) revert();
        if (balances[_to] + _value < balances[_to]) revert();

        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);

        return true;
    }

    function sell() returns (bool success) {
        if(rate == 0) revert();

        uint256 numberTokens = balances[msg.sender];
        uint256 valueWei = numberTokens * rate;
        if(valueWei == 0) revert();

        balances[msg.sender] -= numberTokens;
        total -= numberTokens;
        msg.sender.transfer(valueWei * 1 wei);
        Sell(msg.sender, valueWei , rate);

        return true;
    }

    function () payable {
        if(rate == 0) revert();
        if(msg.value == 0) revert();

        uint256 numberTokens = msg.value / rate;
        if(numberTokens == 0) revert();

        balances[msg.sender] += numberTokens;
        total += numberTokens;
        Buy(msg.sender, numberTokens, rate);
    }
}
