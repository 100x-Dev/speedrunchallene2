pragma solidity 0.8.20; // Do not change the Solidity version
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    /**
     * @notice Buy tokens by sending ETH
     */
    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy some tokens");

        uint256 amountToBuy = msg.value * tokensPerEth;

        // Ensure the vendor has enough tokens
        require(yourToken.balanceOf(address(this)) >= amountToBuy, "Vendor has insufficient tokens");

        // Transfer tokens to buyer
        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    /**
     * @notice Sell tokens in exchange for ETH
     */
    function sellTokens(uint256 tokenAmountToSell) public {
        // Check that the requested amount of tokens to sell is more than 0
        require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = yourToken.balanceOf(msg.sender);
        require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

        // Check that the Vendor's balance is enough to do the swap
        uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
        uint256 ownerETHBalance = address(this).balance;
        require(ownerETHBalance >= amountOfETHToTransfer, "Vendor has not enough funds to accept the sell request");

        bool sent = yourToken.transferFrom(msg.sender, address(this), tokenAmountToSell);
        require(sent, "Failed to transfer tokens from user to vendor");

        (sent, ) = msg.sender.call{ value: amountOfETHToTransfer }("");
        require(sent, "Failed to send ETH to the user");
    }

    /**
     * @notice Withdraw ETH from the contract (only owner)
     */
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "No balance to withdraw");

        (bool sent, ) = msg.sender.call{ value: ownerBalance }("");
        require(sent, "Failed to send ETH to owner");
    }

    // Allow contract to receive ETH
    receive() external payable {}
}
