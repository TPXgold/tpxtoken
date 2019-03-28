pragma solidity 0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    
    uint8 public decimals;
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
    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TPXTeamTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when first 25% of token release amount is enabled
    // 1st July 2019
    uint256 public firstReleaseTime = 1561939200;

    // timestamp when second 25% of token release amount is enabled
    // 1st January 2020
    uint256 public secondReleaseTime = 1577836800;

    // timestamp when third 25% of token release amount is enabled
    // 1st July 2020
    uint256 public thirdReleaseTime = 1593561600;

    // timestamp when fourth 25% of token release amount is enabled
    // 1st January 2021
    uint256 public fourthReleaseTime = 1609459200;
    
    uint8 releasedPeriods;

    // Decimals of the using token
    uint256 public decimals;

    constructor(ERC20Basic _token, address _beneficiary) public {
        token = _token;
        beneficiary = _beneficiary;
        decimals = token.decimals();
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        
        uint256 amount = _getAmount();

        token.safeTransfer(beneficiary, amount);
    }
    
    function _getPeriods() internal view returns(uint8) {
        // solium-disable-next-line security/no-block-members
        if (now >= fourthReleaseTime && releasedPeriods < 4) {
            return 4;
        // solium-disable-next-line security/no-block-members
        } else if (now >= thirdReleaseTime && releasedPeriods < 3) {
            return 3;
        // solium-disable-next-line security/no-block-members
        } else if (now >= secondReleaseTime && releasedPeriods < 2) {
            return 2;
        // solium-disable-next-line security/no-block-members
        } else if (now >= firstReleaseTime && releasedPeriods < 1) {
            return 1;
        } else {
            revert();
        }
    }
    
    function _getAmount() internal returns(uint256) {
        uint8 _periodsPast = _getPeriods();
        uint256 _amount = (_periodsPast - releasedPeriods) * uint256(20000) * uint256(10) ** uint256(decimals);
        releasedPeriods = _periodsPast;
        return _amount;
    }
}
