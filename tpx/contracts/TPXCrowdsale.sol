pragma solidity 0.4.24;


contract OraclizeI {
    address public cbAddress;
    function setProofType(byte _proofType) external;
    
    function query(uint _timestamp, string _datasource, string _arg)
        external
        payable
        returns (bytes32 _id);
        
    function getPrice(string _datasource) public returns (uint _dsprice);
}


contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}


contract UsingOraclize {
    byte constant internal proofType_Ledger = 0x30;
    byte constant internal proofType_Android = 0x40;
    byte constant internal proofStorage_IPFS = 0x01;
    uint8 constant internal networkID_auto = 0;
    uint8 constant internal networkID_mainnet = 1;
    uint8 constant internal networkID_testnet = 2;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;

    modifier oraclizeAPI {
        if ((address(OAR) == 0)||(getCodeSize(address(OAR)) == 0))
            oraclize_setNetwork(networkID_auto);

        if (address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool) {
        return oraclize_setNetwork();
        /* solium-disable-next-line */
        networkID; // silence the warning and remain backwards compatible
    }

    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg)
        oraclizeAPI
        internal
        returns (bytes32 id)
    {
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_cbAddress() internal oraclizeAPI returns (address) {
        return oraclize.cbAddress();
    }

    function oraclize_setProof(byte proofP) internal oraclizeAPI {
        return oraclize.setProofType(proofP);
    }

    function getCodeSize(address _addr) internal view returns(uint _size) {
        /* solium-disable-next-line */
        assembly {
            _size := extcodesize(_addr)
        }
    }

    /* solium-disable-next-line */ // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    string public oraclize_network_name;

    function oraclize_setNetworkName(string _networkName) internal {
        oraclize_network_name = _networkName;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint256 a, uint256 power) internal pure returns (uint256 result) {
        assert(a >= 0);
        result = 1;
        for (uint256 i = 0; i < power; i++) {
            result *= a;
            assert(result >= a);
        }
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function mint(
        address _to,
        uint256 _amountusingOraclize
    )
        public
        returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) public onlyOwner returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] addrs) public onlyOwner returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) public onlyOwner returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] addrs) public onlyOwner returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}


contract PriceChecker is UsingOraclize {

    uint256 public goldPrice; //price in cents with precision
    uint256 public priceETHUSD; //price in cents
    uint256 public centsInDollar = 100;
    uint256 public goldPrecision = 10000;
    uint256 public lastEthPriceUpdate; //timestamp of the last ETH price updating
    uint256 public lastGoldPriceUpdate; //timestamp of the last gold price updating
    
    bytes32 internal goldId;
    bytes32 internal ethId;

    event NewOraclizeQuery(string description);
    event GoldPriceUpdated(uint256 price);
    event EthPriceUpdated(uint256 price);

    constructor() public {
        oraclize_setProof(proofType_Android | proofStorage_IPFS);
    }

    /**
     * @dev Reverts if the timestamp of the last price updating
     * @dev is older than one hour two minutes.
     */
    modifier onlyActualPrice {
        /* solium-disable-next-line */
        require(lastEthPriceUpdate > now - 3600 * 24 - 120);
        /* solium-disable-next-line security/no-block-members,*/
        require(lastGoldPriceUpdate > now - 3600 * 24 - 120);
        _;
    }

    /**
    * @dev Receives the response from oraclize.
    */
    function __callback(bytes32 _myid, string _result, bytes _proof) public {
        if (msg.sender != oraclize_cbAddress()) revert();
        if (_myid == ethId) {
            priceETHUSD = parseInt(_result, 2);
            /* solium-disable-next-line */
            lastEthPriceUpdate = now;
            emit EthPriceUpdated(priceETHUSD);
        } else if (_myid == goldId) {
            goldPrice = parseInt(_result, 8) / 311035;
            /* solium-disable-next-line */
            lastGoldPriceUpdate = now;
            emit GoldPriceUpdated(priceETHUSD);
        } else revert();
        /* solium-disable-next-line */
        if (lastEthPriceUpdate > now - 300 && lastGoldPriceUpdate > now - 300)
            _update(3600 * 24);
        return;/* solium-disable-next-line */
        _proof; //to silence the compiler warning
    }
    
    /**
     * @dev Cyclic query to update ETHUSD price. Period is one hour.
     */
    function _update(uint256 _timeout) internal {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit NewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            ethId = oraclize_query(_timeout, "URL", "json(https://api.coinmarketcap.com/v1/ticker/ethereum/).0.price_usd");
            goldId = oraclize_query(_timeout, "URL", "json(https://data-asg.goldprice.org/dbXRates/USD).items.0.xauPrice");
        }
    }
}


/**
 * @title TPXCrowdsale
 * @dev TPXCrowdsale is a contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the surface of crowdsales.
 */
contract TPXCrowdsale is PriceChecker, Pausable {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // Amount of wei raised
    uint256 public weiRaised;

    // Whether the crowdsale has finished
    bool public crowdsaleFinished;

    // Amount of USD raised in units
    uint256 public usdRaised;

    uint256 public unitsToInt = 10 ** 18;

    /**
     * Event for token purchase logging
     * @param purchaser who paid and got for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        uint256 value,
        uint256 amount
    );

    /**
     * Event for logging of the crowdsale finish
     * @param weiRaised Amount of wei raised during the crowdsale
     * @param usdRaised Amount of usd raised during the crowdsale (in units)
     */
    event CrowdsaleFinished(uint256 weiRaised, uint256 usdRaised);

    /**
    * @dev Reverts if crowdsale has finished.
    */
    modifier onlyWhileOpen {
        require(!crowdsaleFinished);
        _;
    }

    /**
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    constructor(address _wallet, ERC20 _token) public {
        require(_wallet != address(0));
        require(_token != address(0));

        wallet = _wallet;
        token = _token;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    function () external
        payable
        onlyActualPrice
        onlyWhileOpen
        onlyWhitelisted
        whenNotPaused
    {
        buyTokens();
    }

    /**
     * @dev Allows owner to send ETH to the contarct for paying fees or refund.
     */
    function payToContract() external payable onlyOwner { }

    /**
     * @dev Allows owner to withdraw ETH from the contract balance.
     */
    function withdrawFunds(address _beneficiary, uint256 _weiAmount)
        external
        onlyOwner
    {
        require(address(this).balance > _weiAmount);
        _beneficiary.transfer(_weiAmount);
    }

    /**
     * @dev Alows owner to finish the crowdsale
     */
    function finishCrowdsale() external onlyOwner onlyWhileOpen {
        crowdsaleFinished = true;
        emit CrowdsaleFinished(weiRaised, usdRaised);
    }
    
    /**
     * @dev Overriden inherited method to prevent calling from third persons
     */
    function update(uint256 _timeout) external payable onlyOwner {
        _update(_timeout);
    }

    /**
     * @dev Allows owner to transfer TPX tokens
     * @dev from the crowdsale smart contract balance
     */
    function transferTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        external
        onlyOwner
    {
        require(token.balanceOf(address(this)) >= _tokenAmount);
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Allows owner to add raising fund manually
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function buyForFiat(address _beneficiary, uint256 _weiAmount)
        external
        onlyOwner
        onlyWhileOpen
        onlyActualPrice
    {
        _preValidatePurchase(_beneficiary);

        // calculate token amount to be created
        uint256 _tokens = _getTokenAmount(_weiAmount);
        
        require(_tokens >= 10 ** 18);

        // update state
        weiRaised = weiRaised.add(_weiAmount);

        _processPurchase(_beneficiary, _tokens);
        emit TokenPurchase(
            _beneficiary,
            _weiAmount,
            _tokens
        );
    }

    /**
     * @dev low level token purchase
     */
    function buyTokens()
        public
        payable
        onlyWhileOpen
        onlyWhitelisted
        whenNotPaused
        onlyActualPrice
    {

        address _beneficiary = msg.sender;

        uint256 _weiAmount = msg.value;
        _preValidatePurchase(_beneficiary);

        // calculate token amount to be created
        uint256 _tokens = _getTokenAmount(_weiAmount);
        
        require(_tokens >= 10 ** 18);

        // update state
        weiRaised = weiRaised.add(_weiAmount);

        _processPurchase(_beneficiary, _tokens);
        emit TokenPurchase(msg.sender, _weiAmount, _tokens);

        _forwardFunds();
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements
     * @dev to revert state when conditions are not met.
     * @param _beneficiary Address performing the token purchase
     */
    function _preValidatePurchase(address _beneficiary) internal pure {
        require(_beneficiary != address(0));
    }

    /**
     * @dev Source of tokens. The way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        token.transferFrom(owner, _beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev The way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
        internal returns (uint256)
    {
        uint256 _usdUnits = _weiAmount.mul(priceETHUSD) / centsInDollar;
        
        usdRaised = usdRaised.add(_usdUnits);
        
        uint256 _tokenUnitsAmount = _usdUnits.mul(goldPrecision) / goldPrice;
        
        return _tokenUnitsAmount;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
