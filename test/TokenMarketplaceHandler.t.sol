// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Test} from "forge-std/Test.sol";
import {TokenMarketplace} from "../src/TokenMarketplace.sol";
import {OrderInfo} from "../src/types/Trade.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MarketplaceHandler is Test {
    ERC20Mock public token;
    TokenMarketplace public marketplace;

    address public seller = makeAddr("seller");
    address public buyer = makeAddr("buyer");

    uint256 public marketplaceTokensBought;
    uint256 public openOrderTokens;

    constructor(ERC20Mock _token, TokenMarketplace _marketplace) {
         token = _token;
         marketplace = _marketplace;
    }

    function buyFromMarketplace(uint256 amount) public {
        uint256 inventory = marketplace.getAvailableMarketplaceTokens();

        if (inventory == 0) return;
        amount = bound(amount, 1, inventory);

        vm.deal(buyer, amount * 1 ether);
        vm.prank(buyer);
        marketplace.buyTokensFromMarketplace{value: amount * 1 ether}(amount);

        marketplaceTokensBought+=amount;
    }
}