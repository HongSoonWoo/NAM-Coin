pragma solidity ^0.4.18;

import 'https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'https://github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol';
import 'https://github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'https://github.com/OpenZeppelin/zeppelin-solidity/contracts/lifecycle/Pausable.sol';



contract NamCoin is StandardToken, Ownable {
    string public name = "Nam Coin"; //Token name
    string public symbol = "NAM"; //Identifier
    uint8 public constant decimals = 18; //How many decimals to show. To be standard complicant keep it 18
    uint256 public unitsOneEthCanBuy = 120048;     // Approximately 0.00000833 ETH per Nam coin, means 120048 Nam Coin per ETH
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We'll store the total ETH raised via our ICO here.  
    address public fundsWallet; //ETH wallet
    uint public constant crowdsaleSupply = 60 * (uint(10)**9) * (uint(10)**decimals); // 60 billion NAM available for the crowdsale
    uint public constant tokenContractSupply = 60 * (uint(10)**9) * (uint(10)**decimals); // 60 billion NAM (50% of 120)

    // Allow the owner to change the pricing
    function setUnitsOneEthCanBuy(uint256 new_unitsOneEthCanBuy) public onlyOwner
    {
        unitsOneEthCanBuy = new_unitsOneEthCanBuy;
    }
    
    // Allow the owner to transfer tokens from the token contract
    function issueTokens(address _to, uint256 _amount) public onlyOwner
    {
        require(_to != 0x0);
        this.transfer(_to, _amount);
    }
    
    // Allow the owner to manually transfer the collected ether
    // after the crowdsale has ended.
    function transferCollectedEther(address _to) public onlyOwner
    {
        require(_to != 0x0);
        require(!crowdsaleRunning);
        _to.transfer(this.balance);
    }
    
    bool public crowdsaleRunning = false;
    uint256 public crowdsaleStartTimestamp;
    uint256 public crowdsaleDuration = 60 * 24*60*60; // 60 days
    
    function startCrowdsale() public onlyOwner
    {
        crowdsaleRunning = true;
        crowdsaleStartTimestamp = now;
    }
    
    function stopCrowdsale() public onlyOwner
    {
        crowdsaleRunning = false;
    }
    
    // token purchase lower limit for bonus calculation
    uint256 public purchaseGold = 10 * (uint(10)**6) * (uint(10)**decimals);
    uint256 public purchaseSilver = 5 * (uint(10)**6) * (uint(10)**decimals);
    uint256 public purchaseBronze = 3 * (uint(10)**6) * (uint(10)**decimals);
    uint256 public purchaseCoffee = 1 * (uint(10)**6) * (uint(10)**decimals);

    function NamCoin(address _fundsWallet) public {
        fundsWallet = _fundsWallet;
        
        totalSupply_ = crowdsaleSupply + tokenContractSupply;
        
        balances[fundsWallet] = crowdsaleSupply;
        Transfer(0x0, fundsWallet, crowdsaleSupply);
        
        balances[this] = tokenContractSupply;
        Transfer(0x0, this, tokenContractSupply);
    }

    function() payable public {
        // If the crowdsale is not running, cancel the transaction
        require(crowdsaleRunning);
        
        // If the 60-day crowdsale is over, cancel the transaction
        require(now <= crowdsaleStartTimestamp + crowdsaleDuration);
        
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy * (uint(10)**decimals) / (1 ether);
        
        // add bonus based on token purchased  (20%, 15%, 5%, 3%)
        if (amount >= purchaseGold) {
            amount = amount.mul(120).div(100);  

        }else if (amount >= purchaseSilver) {
            amount = amount.mul(115).div(100);

        }else if (amount >= purchaseBronze) {
            amount = amount.mul(110).div(100);

        }else if (amount >= purchaseCoffee) {
            amount = amount.mul(103).div(100);

        }else {
            amount = amount.mul(100).div(100);
        }
        
        // Verify that the hardcap has not been reached
       require (balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)  public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}
