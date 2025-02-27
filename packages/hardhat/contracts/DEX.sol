// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @author
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons.
 *      These reserves will provide liquidity that allows anyone to swap between the assets.
 *      NOTE: functions outlined here are what work with the front end of this challenge.
 *      Also return variable names need to be specified exactly may be referenced (It may be helpful to cross reference with front-end code function calls).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 token; // instantiates the imported contract

    // Total liquidity in the DEX
    uint256 public totalLiquidity;
    // Tracks liquidity provided by each user
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address swapper, uint256 tokenOutput, uint256 ethInput);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address swapper, uint256 tokensInput, uint256 ethOutput);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(
        address liquidityRemover,
        uint256 liquidityWithdrawn,
        uint256 tokensOutput,
        uint256 ethOutput
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr); // specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Initializes the amount of tokens that will be transferred to the DEX from the ERC20 mintee (and only them based on how Balloons.sol is written).
     *         Loads contract up with both ETH and Balloons.
     * @param tokens Amount to be transferred to DEX
     * @return totalLiquidity The number of liquidity provider tokens (LPTs) minted as a result of the deposit
     * NOTE: since the ratio is 1:1, this is fine to initialize the totalLiquidity (w.r.t. Balloons) as equal to the ETH balance of the contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        // Ensure the DEX is only initialized once
        require(totalLiquidity == 0, "DEX already initialized");

        // Set total liquidity equal to the ETH deposited (assumes 1:1 ratio)
        totalLiquidity = address(this).balance;

        // Record the liquidity provided by the sender
        liquidity[msg.sender] = totalLiquidity;

        // Transfer tokens from the sender to the DEX contract
        // The sender must have approved the DEX to spend their tokens beforehand
        require(token.transferFrom(msg.sender, address(this), tokens), "Token transfer failed");

        return totalLiquidity;
    }

    /**
     * @notice Returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follows the constant product formula: (xReserves + xInputWithFee) * (yReserves - yOutput) = xReserves * yReserves,
     *      where xInputWithFee = xInput * 997 (accounting for a 0.3% fee) and the fee denominator is 1000.
     */
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        yOutput = numerator / denominator;
    }

    /**
     * @notice Returns liquidity for a user.
     * NOTE: This is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result.
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice Sends Ether to DEX in exchange for $BAL.
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        // Implementation goes here...
    }

    /**
     * @notice Sends $BAL tokens to DEX in exchange for Ether.
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        // Implementation goes here...
    }

    /**
     * @notice Allows deposits of $BAL and $ETH to liquidity pool.
     *         NOTE: msg.value is used to determine the amount of $BAL needed and taken from the depositor.
     *         NOTE: The user must approve the DEX to spend their tokens beforehand.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        // Implementation goes here...
    }

    /**
     * @notice Allows withdrawal of $BAL and $ETH from liquidity pool.
     *         NOTE: With low liquidity, the user may receive very little back.
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        // Implementation goes here...
    }
}
