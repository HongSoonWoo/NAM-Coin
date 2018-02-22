pragma solidity ^0.4.18;


import "./Ownable.sol";
import "./ERC20Basic.sol";
import "./SafeMath.sol";


//--------------- Based on Crowdsale.sol -----------

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract NamCoinCrowdsaleNew is Ownable {
    using SafeMath for uint256;

    // The token being sold
    ERC20Basic public tokenContract;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public crowdsaleStartTime;
    uint256 public crowdsaleDuration = 40 days;
    uint256 public crowdsaleEndTime;

    // address where funds are collected
    address public wallet;

    //-------------- Add -------------------
    uint256 public rate;

    function setRate(uint256 new_rate) public onlyOwner {
        rate = new_rate;
    }

    // amount of raised money in wei
    uint256 public weiRaised;

    // minimum purchase: 0.5 ETH
    uint256 public minPurchaseInWei = 0.5 ether;

    modifier isMinimum() {
        require(msg.value >= minPurchaseInWei);
        _;
    }

    // manually start and stop crowdsale
    bool public crowdsaleRunning = false;

    function startCrowdsale() public onlyOwner
    {
        crowdsaleRunning = true;
        crowdsaleStartTime = now;
        crowdsaleEndTime = crowdsaleStartTime + crowdsaleDuration;
    }

    function stopCrowdsale() public onlyOwner
    {
        crowdsaleRunning = false;
    }

    // Allow the owner to transfer tokens from the token contract
    function issueTokens(address _to, uint256 _amount) public onlyOwner
    {
        require(_to != 0x0);
        tokenContract.transfer(_to, _amount);
    }

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function NamCoinCrowdsaleNew(address _newFundsWallet, address _erc20) public {

        require(_newFundsWallet != address(0));
        require(_erc20 != address(0));

        tokenContract = ERC20Basic(_erc20);

        wallet = _newFundsWallet;
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public isMinimum() payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        tokenContract.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return !crowdsaleRunning || now > crowdsaleEndTime;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    /*function createTokenContract() internal returns (MintableToken) {
      return new MintableToken();
    }*/


    // Override this method to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        // return weiAmount.mul(rate());
        return weiAmount.mul(rate);
    }


    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= crowdsaleStartTime && now <= crowdsaleEndTime;
        bool nonZeroPurchase = msg.value != 0;
        return crowdsaleRunning && withinPeriod && nonZeroPurchase;
    }

}
