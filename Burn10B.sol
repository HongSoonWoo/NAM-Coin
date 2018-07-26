totalSale = 50 * (10 ** 9) * (10 ** uint256(decimals));
totalAirdrop = 10 * (10 ** 9) * (10 ** uint256(decimals));
	
// Allow the owner to transfer tokens from the token contract
function issueTokens(address _to, uint256 _amount) public
{
	require(msg.sender == owner || msg.sender == airdrop);
	require(_to != address(0));
	if (msg.sender == owner){
		totalSaled = totalSaled.add(_amount);
		require(totalSaled <= totalSale);
	}
	else if (msg.sender == airdrop) {
		totalAirdroped = totalAirdrop.add(_amount);
		require(totalAirdroped <= totalAirdrop);
	}
	else revert();
	tokenContract.transfer(_to, _amount);
}