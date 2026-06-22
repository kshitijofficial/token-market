// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Test} from "forge-std/Test.sol";
import {TokenMarketplace} from "../src/TokenMarketplace.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "forge-std/console.sol";

contract TokenMarketplaceTest is Test {
    TokenMarketplace public tokenMarketplace;
    ERC20Mock public erc20Mock;
    address buyer = makeAddr("buyer");


    error TokenMarketplace_ZeroNumberOfTokens(uint256 numberOfTokens);
    error TokenMarketplace_InsufficientEthPayment(uint256 expectedPayment,uint256 actualPayment);

    function setUp() public {
        address owner = makeAddr("owner");
        erc20Mock = new ERC20Mock();
        tokenMarketplace = new TokenMarketplace(address(erc20Mock), owner);
        erc20Mock.mint(address(tokenMarketplace), 1000);
    }

    function testBuyTokensFromMarketplace() public {
        uint256 tokensToBuyFromMarketplace = 2;
        uint256 tokenPrice = tokenMarketplace.TOKEN_PRICE();
        uint256 totalPriceToPayToBuyTokens = tokensToBuyFromMarketplace *
            tokenPrice;
        uint256 tokenMarketplaceEthBalanceBefore = address(tokenMarketplace)
            .balance;
        
        uint256 tokenBalanceOfBuyerBefore = erc20Mock.balanceOf(buyer);

        vm.prank(buyer);
        vm.deal(buyer, 10 ether);

        tokenMarketplace.buyTokensFromMarketplace{
            value: totalPriceToPayToBuyTokens
        }(tokensToBuyFromMarketplace);
        
        uint256 tokenMarketplaceEthBalanceAfter = address(tokenMarketplace)
            .balance;
        uint256 tokenBalanceOfBuyerAfter = erc20Mock.balanceOf(buyer);

        assertEq(
            tokenMarketplaceEthBalanceAfter - tokenMarketplaceEthBalanceBefore,
            totalPriceToPayToBuyTokens
        );
        assertEq(
            tokenBalanceOfBuyerAfter - tokenBalanceOfBuyerBefore,
            tokensToBuyFromMarketplace
        );
    }

    function test_RevertsWhenNumberOfTokensToBuyFromMarkeplaceIsZero() public {
        uint256 tokensToBuyFromMarketplace = 0;
      
        vm.deal(buyer, 10 ether);
        vm.prank(buyer);

        vm.expectRevert(
            abi.encodeWithSelector(
                TokenMarketplace_ZeroNumberOfTokens.selector,
                tokensToBuyFromMarketplace
            )
        );
        tokenMarketplace.buyTokensFromMarketplace{value: 1 ether}(
            tokensToBuyFromMarketplace
        );
    }

    function test_FuzzBuyTokensFromMarketplace(
        uint256 tokensToBuyFromMarketplace
    ) public {
        // vm.assume(tokensToBuyFromMarketplace < 1000);
        tokensToBuyFromMarketplace = bound(tokensToBuyFromMarketplace, 1, 1000);
        uint256 tokenPrice = tokenMarketplace.TOKEN_PRICE();
        uint256 totalPriceToPayToBuyTokens = tokensToBuyFromMarketplace *
            tokenPrice;
        uint256 tokenMarketplaceEthBalanceBefore = address(tokenMarketplace)
            .balance;
        
        uint256 tokenBalanceOfBuyerBefore = erc20Mock.balanceOf(buyer);

        vm.prank(buyer);
        vm.deal(buyer, totalPriceToPayToBuyTokens);
        tokenMarketplace.buyTokensFromMarketplace{
            value: totalPriceToPayToBuyTokens
        }(tokensToBuyFromMarketplace);
        uint256 tokenMarketplaceEthBalanceAfter = address(tokenMarketplace)
            .balance;
        uint256 tokenBalanceOfBuyerAfter = erc20Mock.balanceOf(buyer);

        assertEq(
            tokenMarketplaceEthBalanceAfter - tokenMarketplaceEthBalanceBefore,
            totalPriceToPayToBuyTokens
        );
        assertEq(
            tokenBalanceOfBuyerAfter - tokenBalanceOfBuyerBefore,
            tokensToBuyFromMarketplace
        );
    }

    function test_fuzz_buyTokensFromMarketplace_revertsWrongEth(
        uint256 numberOfTokensToBuy,
        uint256 ethAmount
    ) public {
        numberOfTokensToBuy = bound(numberOfTokensToBuy, 1, 1000);

        uint256 correctEthAmount = numberOfTokensToBuy * 1 ether;

        ethAmount = bound(ethAmount, 0, 10_000 ether);
        vm.assume(ethAmount != correctEthAmount);

        vm.deal(buyer, ethAmount);
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(TokenMarketplace_InsufficientEthPayment.selector, correctEthAmount, ethAmount)
        );
        tokenMarketplace.buyTokensFromMarketplace{value: ethAmount}(numberOfTokensToBuy);
    }


}
