// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Test} from "forge-std/Test.sol";
import {TokenMarketplace} from "../src/TokenMarketplace.sol";
import {OrderInfo} from "../src/types/Trade.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "forge-std/console.sol";

contract TokenMarketplaceTest is Test {
    uint256 constant DEFAULT_NUMBER_OF_MINTED_TOKENS = 1000;
    TokenMarketplace public tokenMarketplace;
    ERC20Mock public erc20Mock;

    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");


    error TokenMarketplace_ZeroNumberOfTokens(uint256 numberOfTokens);
    error TokenMarketplace_InsufficientEthPayment(uint256 expectedPayment,uint256 actualPayment);
    error TokenMarketplace_InsufficientTokenBalance(uint256 actualTokens,uint256 expectedTokens);
    error TokenMarketplace_InsufficientAllowance(uint256 allowedTokens,uint256 tokensToTransfer);

    function _mintSLVTokens(address addr, uint256 numberOfTokensToMint) internal {
        erc20Mock.mint(addr, numberOfTokensToMint);
    }

   function _approveTokens(address tokenOwner,address spender,uint256 approvalAmount
   ) internal{
        vm.prank(tokenOwner);
        erc20Mock.approve(spender, approvalAmount);
    }

    function setUp() public {
        address owner = makeAddr("owner");
        erc20Mock = new ERC20Mock();
        tokenMarketplace = new TokenMarketplace(address(erc20Mock), owner);
        _mintSLVTokens(address(tokenMarketplace), DEFAULT_NUMBER_OF_MINTED_TOKENS);
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

    function test_fuzz_buyTokensFromMarketplace_revertsWhenAmountExceedsInventory(
        uint256 numberOfTokensToBuy
    ) public {
        numberOfTokensToBuy = bound(numberOfTokensToBuy, DEFAULT_NUMBER_OF_MINTED_TOKENS + 1, 10_000);
        uint256 ethAmount = numberOfTokensToBuy * 1 ether;
        vm.deal(buyer, ethAmount);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenMarketplace_InsufficientTokenBalance.selector,
                DEFAULT_NUMBER_OF_MINTED_TOKENS,
                numberOfTokensToBuy
            )
        );
        tokenMarketplace.buyTokensFromMarketplace{value: ethAmount}(numberOfTokensToBuy);
    }

     function test_fuzz_createSellOrder(uint256 numberOfTokensToSell,uint256 numberOfTokensToApprove,uint256 numberOfTokensToMint) public {
        numberOfTokensToMint = bound(numberOfTokensToMint, 1, 1000);
        numberOfTokensToApprove = bound(numberOfTokensToApprove, 1, numberOfTokensToMint);
        numberOfTokensToSell = bound(numberOfTokensToSell, 1, numberOfTokensToApprove);
         _mintSLVTokens(seller, numberOfTokensToMint);
         _approveTokens(seller,address(tokenMarketplace),numberOfTokensToApprove);

        vm.prank(seller);
        tokenMarketplace.createSellOrder(numberOfTokensToSell);

        uint256 createdOrderId = tokenMarketplace.getNumberOfCreatedOrders() - 1;
        OrderInfo memory order = tokenMarketplace.getCreatedOrderById(createdOrderId);
        
        assertEq(createdOrderId, order.orderId);
        assertEq(seller, order.seller);
        assertEq(true, order.isActive);
        assertEq(numberOfTokensToSell, order.numberOfTokensToSell);
        assertEq(erc20Mock.allowance(seller, address(tokenMarketplace)), numberOfTokensToApprove - numberOfTokensToSell);
    }

    function test_fuzz_createSellOrder_revertsWhenSellAmountExceedsBalance(
        uint256 numberOfTokensToSell,
        uint256 numberOfTokensToMint
    ) public {
        numberOfTokensToMint = bound(numberOfTokensToMint, 0, 1000);
        numberOfTokensToSell = bound(numberOfTokensToSell, numberOfTokensToMint + 1, 10_000);
        _mintSLVTokens(seller, numberOfTokensToMint);

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenMarketplace_InsufficientTokenBalance.selector,
                numberOfTokensToMint,
                numberOfTokensToSell
            )
        );
        tokenMarketplace.createSellOrder(numberOfTokensToSell);
    }

    function test_fuzz_createSellOrder_revertsWhenSellAmountExceedsAllowance(
        uint256 numberOfTokensToSell,
        uint256 numberOfTokensToApprove,
        uint256 numberOfTokensToMint
    ) public {
        numberOfTokensToMint = bound(numberOfTokensToMint, 1, 1000);
        numberOfTokensToSell = bound(numberOfTokensToSell, 1, numberOfTokensToMint);
        numberOfTokensToApprove = bound(numberOfTokensToApprove, 0, numberOfTokensToSell - 1);
        _mintSLVTokens(seller, numberOfTokensToMint);
        _approveTokens(seller,address(tokenMarketplace),numberOfTokensToApprove);

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                TokenMarketplace_InsufficientAllowance.selector,
                numberOfTokensToApprove,
                numberOfTokensToSell
            )
        );
        tokenMarketplace.createSellOrder(numberOfTokensToSell);
    }

    
    function test_fuzz_buyTokenFromSeller(uint256 numberOfTokensToSell,uint256 numberOfTokensToApprove,uint256 numberOfTokensToMint,uint256 numberOfTokensToBuy) public {
        numberOfTokensToMint = bound(numberOfTokensToMint, 1, 1000);
        numberOfTokensToApprove = bound(numberOfTokensToApprove, 1, numberOfTokensToMint);
        numberOfTokensToSell = bound(numberOfTokensToSell, 1, numberOfTokensToApprove);
        numberOfTokensToBuy = bound(numberOfTokensToBuy,1,numberOfTokensToSell);
        _mintSLVTokens(seller, numberOfTokensToMint);
        _approveTokens(seller,address(tokenMarketplace),numberOfTokensToApprove);
        vm.prank(seller);
        tokenMarketplace.createSellOrder(numberOfTokensToSell);
        uint256 orderId = tokenMarketplace.getNumberOfCreatedOrders() - 1;
        uint256 ethAmount = numberOfTokensToBuy * 1 ether;
        uint256 buyerTokenBeforeBalance = erc20Mock.balanceOf(buyer);

        vm.deal(buyer, ethAmount);
        vm.prank(buyer);
        tokenMarketplace.buyTokensFromSellOrderCreated{value: ethAmount}(orderId, numberOfTokensToBuy);
    
        uint256 buyerTokenAfterBalance = erc20Mock.balanceOf(buyer);
        OrderInfo memory order = tokenMarketplace.getCreatedOrderById(orderId);
        assertEq(buyerTokenAfterBalance - buyerTokenBeforeBalance, numberOfTokensToBuy);
        assertEq(order.numberOfTokensToSell, numberOfTokensToSell - numberOfTokensToBuy);
        assertEq(order.isActive, numberOfTokensToBuy < numberOfTokensToSell);
    }
     

    


}
