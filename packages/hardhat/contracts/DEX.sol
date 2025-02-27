// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @notice A decentralized exchange that holds reserves of ETH and tokens.
 *         It supports swaps between ETH and $BAL tokens using a constant product pricing model.
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 token; // Instantiates the imported token contract

    // Total liquidity in the DEX (represents the total Liquidity Provider Tokens minted)
    uint256 public totalLiquidity;
    // Tracks liquidity provided by each user
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    event EthToTokenSwap(address swapper, uint256 tokenOutput, uint256 ethInput);
    event TokenToEthSwap(address swapper, uint256 tokensInput, uint256 ethOutput);
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);
    event LiquidityRemoved(
        address liquidityRemover,
        uint256 liquidityWithdrawn,
        uint256 tokensOutput,
        uint256 ethOutput
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Initializes the DEX with both ETH and tokens.
     * @param tokens Amount of tokens to be transferred to the DEX
     * @return totalLiquidity The liquidity provider tokens minted
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX already initialized");

        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;

        require(token.transferFrom(msg.sender, address(this), tokens), "Token transfer failed");
        return totalLiquidity;
    }

    /**
     * @notice Calculates the output amount for a given input using the constant product formula.
     * @dev Uses a 0.3% fee by applying a multiplier of 997/1000 to the input amount.
     * @param xInput Amount of input asset (ETH or tokens)
     * @param xReserves Reserve of input asset before the swap
     * @param yReserves Reserve of output asset
     * @return yOutput Calculated output amount
     */
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        yOutput = numerator / denominator;
    }

    /**
     * @notice Returns the liquidity for a given address.
     * @param lp The liquidity provider's address.
     * @return The amount of liquidity provided.
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice Swaps ETH for $BAL tokens.
     * @dev The function calculates the token output using the price function.
     *      Note that the ETH reserve is taken as the contract balance minus msg.value.
     * @return tokenOutput The amount of tokens the user receives.
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "Must send ETH");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));

        tokenOutput = price(msg.value, ethReserve, tokenReserve);
        require(tokenOutput <= tokenReserve, "DEX has insufficient tokens");

        require(token.transfer(msg.sender, tokenOutput), "Token transfer failed");
        emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
    }

    /**
     * @notice Swaps $BAL tokens for ETH.
     * @dev The function calculates the ETH output using the price function.
     * @param tokenInput The amount of tokens the user wishes to swap.
     * @return ethOutput The amount of ETH the user receives.
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "Must swap a positive token amount");
        uint256 tokenReserve = token.balanceOf(address(this));
        ethOutput = price(tokenInput, tokenReserve, address(this).balance);
        require(ethOutput <= address(this).balance, "DEX has insufficient ETH");

        require(token.transferFrom(msg.sender, address(this), tokenInput), "Token transfer failed");
        payable(msg.sender).transfer(ethOutput);
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
    }

    /**
     * @notice Allows deposits of ETH and $BAL tokens into the liquidity pool.
     * @dev The depositor must send ETH with the transaction and approve the DEX for the corresponding token amount.
     *      The correct token amount is calculated to maintain the current reserve ratio.
     * @return liquidityMinted The amount of liquidity tokens minted for the depositor.
     */
    function deposit() public payable returns (uint256 liquidityMinted) {
        require(totalLiquidity > 0, "DEX not initialized");
        require(msg.value > 0, "Must send ETH to deposit");

        // Calculate ETH reserve prior to deposit
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));

        // Determine required token amount to maintain ratio
        uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");

        // Calculate liquidity minted based on the ETH deposited
        liquidityMinted = (msg.value * totalLiquidity) / ethReserve;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenAmount);
    }

    /**
     * @notice Allows withdrawal of liquidity from the pool.
     * @dev The function calculates the amount of ETH and tokens to withdraw based on the liquidity tokens burned.
     * @param amount The amount of liquidity tokens the user wishes to withdraw.
     * @return ethAmount The amount of ETH returned.
     * @return tokenAmount The amount of tokens returned.
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(amount > 0, "Withdraw amount must be > 0");
        require(liquidity[msg.sender] >= amount, "Not enough liquidity");

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        // Calculate amounts to withdraw based on the user's share of total liquidity
        ethAmount = (amount * ethReserve) / totalLiquidity;
        tokenAmount = (amount * tokenReserve) / totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        payable(msg.sender).transfer(ethAmount);
        emit LiquidityRemoved(msg.sender, amount, tokenAmount, ethAmount);
    }
}
