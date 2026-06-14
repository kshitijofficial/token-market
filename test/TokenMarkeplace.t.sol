// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Test} from "forge-std/Test.sol";
import {TokenMarketplace} from "../src/TokenMarketplace.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "forge-std/console.sol";   

contract TokenMarketplaceTest is Test {
    TokenMarketplace public tokenMarketplace;
    ERC20Mock public erc20Mock;


    function setUp() public {
        address owner = makeAddr("owner");
        erc20Mock = new ERC20Mock();
        tokenMarketplace = new TokenMarketplace(address(erc20Mock),owner);
        erc20Mock.mint(address(tokenMarketplace),1000);
    }

    function testBuyTokensFromMarketplace() public {
        uint256 tokensToBuyFromMarketplace = 2;
        uint256 tokenPrice = tokenMarketplace.TOKEN_PRICE();
        uint256 totalPriceToPayToBuyTokens = tokensToBuyFromMarketplace*tokenPrice;
        uint256 tokenMarketplaceEthBalanceBefore = address(tokenMarketplace).balance;
        address buyer = makeAddr("buyer");
        uint256 tokenBalanceOfBuyerBefore = erc20Mock.balanceOf(buyer);
       
        vm.prank(buyer);
        vm.deal(buyer,10 ether);
        tokenMarketplace.buyTokensFromMarketplace{value: totalPriceToPayToBuyTokens}(tokensToBuyFromMarketplace);
        uint256 tokenMarketplaceEthBalanceAfter = address(tokenMarketplace).balance;
        uint256 tokenBalanceOfBuyerAfter = erc20Mock.balanceOf(buyer);

        assertEq(tokenMarketplaceEthBalanceAfter-tokenMarketplaceEthBalanceBefore, totalPriceToPayToBuyTokens);
        assertEq(tokenBalanceOfBuyerAfter-tokenBalanceOfBuyerBefore, tokensToBuyFromMarketplace);
    }


    
    

  
}
