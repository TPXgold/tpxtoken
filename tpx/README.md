# TPX's Crowdsale Contracts

Please see below TPXCrowdsale smart contracts for the TPX crowdsale.


TPX is an ERC-20 compliant cryptocurrency built on top of the [Ethereum][ethereum] blockchain.


## Contracts

Please see the [contracts/](contracts) directory.

## The Crowdsale Specification
*	TPX token is ERC-20 compliant.
*	Token allocation:
	* 1'000'000 tokens will be offered for sale.
	* 20'000 will be offered for marketing, airdrops and bounty program.
	* 80'000 will be offered to the team.
	* Total supply is 1'100'000 tokens.

## TPX PRICING PROGRAM
The price is set in gold gram. The ETH/USD price takes from [coinmarketcap.com open api](https://api.coinmarketcap.com/v1/ticker/ethereum/).
The gold/USD price takes from [goldprice.org open api](https://data-asg.goldprice.org/dbXRates/USD).



## Develop

* Contracts are written in [Solidity][solidity] and tested using [Truffle][truffle] and [ganache-cli][ganache-cli].

* Smart contracts is based on [Open Zeppelin][openzeppelin] smart contracts [1.10.0][openzeppelin_v1.10.0].

## Code

#### TPXCrowdsale Functions


**fallback**
```cs
function () external payable onlyActualPrice onlyWhileOpen onlyWhitelisted whenNotPaused
```
Payable function to buy tokens.


**finishCrowdsale**
```cs
function finishCrowdsale() external onlyOwner onlyWhileOpen
```
Allows owner to finish the crowdsale.  


**buyForFiat**
```cs
function buyForFiat(address _beneficiary, uint256 _weiAmount) external onlyOwner onlyWhileOpen onlyActualPrice
```
Allows owner to add raising fund manually (tokens will purchase automatically).


**buyTokens**
```cs
function buyTokens() public payable onlyWhileOpen onlyWhitelisted whenNotPaused onlyActualPrice
```
Low level token purchase.


**__callback**
```cs
function __callback(bytes32 myid, string result, bytes proof) public
```
Receives the response from oraclize.


**update**
```cs
function update(uint256 _timeout) public payable
```
Cyclic query to update ETH/USD and gold/USD price. Recieves response in [_timeout] seconds.


**addAddressToWhitelist**
```cs
function addAddressToWhitelist(address addr) public onlyOwner returns(bool success)
```
Adds an address to the whitelist.


**addAddressesToWhitelist**
```cs
function addAddressesToWhitelist(address[] addrs) public onlyOwner returns(bool success)
```
Adds addresses to the whitelist.


**removeAddressFromWhitelist**
```cs
function removeAddressFromWhitelist(address addr) public onlyOwner returns(bool success)
```
Removes an address from the whitelist.


**removeAddressesFromWhitelist**
```cs
function removeAddressesFromWhitelist(address[] addrs) public onlyOwner returns(bool success)
```
Removes addresses from the whitelist.


**pause**
```cs
function pause() public onlyOwner whenNotPaused
```
Called by the owner to pause, triggers stopped state.


**unpause**
```cs
function unpause() public onlyOwner whenPaused
```
Called by the owner to unpause, returns to normal state.


**transferOwnership**
```cs
function transferOwnership(address newOwner) public onlyOwner
```
Allows the current owner to set the pendingOwner address.


**claimOwnership**
```cs
function claimOwnership() public onlyPendingOwner
```
Allows the pendingOwner address to finalize the transfer.


**payToContract**
```cs
function payToContract() external	payable	onlyOwner
```
Allows owner to send ETH to the contarct for paying fees or refund.


**withdrawFunds**
```cs
function withdrawFunds(address _beneficiary, uint256 _weiAmount) external onlyOwner
```
Allows owner to withdraw ETH from the contract balance.


#### TPXCrowdsale public variable

**bonuses**
The amount of bonuses minted during the crowdsale (Those are bounty bonuses not discount).

**crowdsaleFinished**
Whether the crowdsale has finished

**lastEthPriceUpdate**
Timestamp of the last ETH price updating.

**lastGoldPriceUpdate**
Timestamp of the last gold price updating.

**owner**
Address of the current owner of the contract.

**paused**
Whether the crowdsale is paused.

**pendingOwner**
Address of the pending owner of the contract.

**priceETHUSD**
Last price ETHUSD from oraclize in cents.

**goldPrice**
Last price in cents with precision.

**token**
Address of the using token.

**centsInDollar**
How much cents in one dollar (100).

**goldPrecision**
Precision for gold (10000).

**usdRaised**
How much USD was raised during the crowdsale.

**wallet**
The address of a wallet specified by owner for forward funds for.

**weiRaised**
Amount of wei was raised during the crowdsale.

**whitelist**
Mapping contains 'true' as a value for addresses allowed to participate in the crowdsale .


#### TPXCrowdsale Events


**OwnershipTransferred**
```cs
event GrantUpdated(address indexed _grantee, uint256 _oldAmount, uint256 _newAmount);
```

**Pause**
```cs
event Pause();
```

**Unpause**
```cs
event Unpause();
```

**WhitelistedAddressAdded**
```cs
event WhitelistedAddressAdded(address addr);
```

**WhitelistedAddressRemoved**
```cs
event WhitelistedAddressRemoved(address addr);
```

**NewOraclizeQuery**
```cs
event NewOraclizeQuery(string description);
```

**GoldPriceUpdated**
```cs
event GoldPriceUpdated(uint256 price);
```

**EthPriceUpdated**
```cs
event EthPriceUpdated(uint256 price);
```

**TokenPurchase**
```cs
event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
```

**CrowdsaleFinished**
```cs
event CrowdsaleFinished(uint256 weiRaised, uint256 usdRaised);
```

### Dependencies

```bash
# Install Truffle and ganache-cli packages globally:
$ npm install -g truffle ganache-cli

# Install local node dependencies:
$ npm install
```

### Test

```bash
$ truffle test --network ganache
```

### Deploy and manage

Use metamask to deploy the smart contracts.
Copy code to [remix browser](https://remix.ethereum.org). Compile the source and click 'Deploy' at the 'Run' tab.
Firstly, you need to deploy TPXToken.sol.
Then copy address of this deployed contract and put it as a second parameter to constructor of TPXCrowdsale.sol. The first parameter is a wallet address for forward funds to.
After deploying approve 1'000'000 TPXTokens from owner address to TPXCrowdsale contract address to allow TPXCrowdsale to manage TPXTokens.
Then you will able to add addresses to whitelist and manage crowdsale and token using functions.
Don't forget to send some ETH to the crowdsale contract to pay oraclize fees using 'update' or 'payToContract' functions.
Notice 'update' function with parameter 'timeout' (in seconds) initiate new update cycle, while 'payToContract' just receives fund.
Then deploy timelock contract with address of token as first and address of team wallet as seconds constructor parameter. This contract will manage team tokens. The team will be able to receive 25% of their tokens every 6 months until they reach the limit.


### Code Coverage

```bash
$ ./node_modules/.bin/solidity-coverage
```

## Collaborators

* **[TailorSwift.io](https://tailorswift.io)**
* **[Ivan Zakharov](https://github.com/IvanZakharov)**


## License

Apache License v2.0


[ethereum]: https://www.ethereum.org/

[solidity]: https://solidity.readthedocs.io/en/develop/
[truffle]: http://truffleframework.com/
[ganache-cli]: https://github.com/trufflesuite/ganache-cli
[openzeppelin]: https://openzeppelin.org
[openzeppelin_v1.10.0]: https://github.com/OpenZeppelin/zeppelin-solidity/releases/tag/v1.10.0
