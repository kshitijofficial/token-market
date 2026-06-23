// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.34;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OrderInfo} from "./types/Trade.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenMarketplace is Ownable,Pausable,ReentrancyGuard{
     using SafeERC20 for IERC20;

     uint256 public constant TOKEN_PRICE = 1 ether;
     uint256 private reseverdOrderedTokens; 
     IERC20 public slvToken;

     mapping(uint256=>OrderInfo) private orders;

     OrderInfo[] private orderList;

     uint256 private nextOrderId;

     error TokenMarketplace_ZeroNumberOfTokens(uint256 numberOfTokens);
     error TokenMarketplace_InsufficientEthPayment(uint256 expectedPayment,uint256 actualPayment);
     error TokenMarketplace_InsufficientTokenBalance(uint256 expectedToken,uint256 actualToken);
     error TokenMarketplace_InsufficientAllowance(uint256 allowedTokens,uint256 tokensToTransfer);
     error TokenMarketplace_OrderIsNotActive(uint256 orderId);
     error TokenMarketplace_NotEnoughTokensInOrder(uint256 expectedTokens,uint256 actualTokens);
     error TokenMarketplace_EthTransferFailed();
     error TokenMarketplace_InvalidOrderId();
     error TokenMarketplace_UnauthorizedSeller(address caller,uint256 orderId);
     error TokenMarkeplace_InvalidOwner();

     event buyTokens(address indexed buyer,uint256 indexed numberOfTokensBought);


     constructor(address _slvToken,address _owner) Ownable(_owner){
         slvToken = IERC20(_slvToken);
     }

    function _getSlvTokenBalanceOfMarketPlace() internal view returns(uint256) {
        return slvToken.balanceOf(address(this));
    }
    function _checkEthPayment(uint256 numberOfTokens) internal view{
    if(numberOfTokens*TOKEN_PRICE!=msg.value){
        revert TokenMarketplace_InsufficientEthPayment(numberOfTokens*TOKEN_PRICE,msg.value);
        }
    }
    function _isNumberOfTokensZero(uint256 numberOfTokens) internal pure  {
        if(numberOfTokens==0){
        revert TokenMarketplace_ZeroNumberOfTokens(numberOfTokens);
        }
    }

    function buyTokensFromMarketplace(uint256 numberOfTokens) external payable whenNotPaused nonReentrant{
        _isNumberOfTokensZero(numberOfTokens);
        _checkEthPayment(numberOfTokens);
        if(_getSlvTokenBalanceOfMarketPlace()<numberOfTokens){
            revert TokenMarketplace_InsufficientTokenBalance(_getSlvTokenBalanceOfMarketPlace(),numberOfTokens);
        }
        //from marketplace to the buyer address
        slvToken.safeTransfer(msg.sender, numberOfTokens);
        emit buyTokens(msg.sender,numberOfTokens);
    }

    function _checkSellerSlvTokenBalance(uint256 numberOfTokens) internal view {
        uint256 balance = slvToken.balanceOf(msg.sender);

        if (numberOfTokens > balance) {
            revert TokenMarketplace_InsufficientTokenBalance(balance,numberOfTokens);
        }
    }

    function createSellOrder(uint256 numberOfTokensToSell) external  {
         _isNumberOfTokensZero(numberOfTokensToSell);
         _checkSellerSlvTokenBalance(numberOfTokensToSell);
        uint256 allowance = slvToken.allowance(msg.sender, address(this));

        if(allowance<numberOfTokensToSell){
            revert TokenMarketplace_InsufficientAllowance(allowance,numberOfTokensToSell);
        }
        OrderInfo memory order = OrderInfo({
                orderId: nextOrderId,
                seller:msg.sender,
                numberOfTokensToSell:numberOfTokensToSell,
                isActive:true
            });
        orders[nextOrderId] = order;
        nextOrderId++;
        slvToken.safeTransferFrom(msg.sender, address(this), numberOfTokensToSell);
        reseverdOrderedTokens+= numberOfTokensToSell;
        orderList.push(order);
    }

    function getNumberOfCreatedOrders() public view returns (uint256) {
       
        return nextOrderId;
    }

    function _validateOrderId(uint256 orderId) internal view {
        uint256 totalNumberOfCreatedOrder = getNumberOfCreatedOrders();
        if (orderId >= totalNumberOfCreatedOrder) {
            revert TokenMarketplace_InvalidOrderId();
        }
    }

    function buyTokensFromSellOrderCreated(uint256 orderId,uint256 numberOfTokensToBuy) external payable whenPaused{
        _validateOrderId(orderId);
        _isNumberOfTokensZero(numberOfTokensToBuy);
        _checkEthPayment(numberOfTokensToBuy);
       
        OrderInfo storage order = orders[orderId];
  
        if(order.isActive == false){
            revert TokenMarketplace_OrderIsNotActive(order.orderId);
        }

        if(order.numberOfTokensToSell<numberOfTokensToBuy){
            revert TokenMarketplace_NotEnoughTokensInOrder(order.numberOfTokensToSell,numberOfTokensToBuy);
        }
        order.numberOfTokensToSell-=numberOfTokensToBuy;

        if(order.numberOfTokensToSell==0){
            order.isActive = false;
        }
        //token transfer from contract to the buyer account
       slvToken.safeTransfer(msg.sender, numberOfTokensToBuy);
  
        //transfe eth from contract to the seller account
        (bool success,) = order.seller.call{value: msg.value}("");
         if(!success){
            revert TokenMarketplace_EthTransferFailed();
         }
        }

    function cancelSellOrder(uint256 orderId) external {
            _validateOrderId(orderId);
            OrderInfo storage order = orders[orderId];
            
            if (order.seller != msg.sender) {
              revert TokenMarketplace_UnauthorizedSeller(msg.sender, orderId);
            }

            //algorithm
            order.isActive = false;
            reseverdOrderedTokens-=order.numberOfTokensToSell;
            slvToken.safeTransfer(order.seller,order.numberOfTokensToSell);
        }

    function getCreatedOrderById(uint256 orderId) external view returns (OrderInfo memory ) {
       
         return orders[orderId];
    }

    // function getAllOrdersTwo() external view returns (OrderInfo[] memory) {
    //     OrderInfo[] memory allOrders = new OrderInfo[](nextOrderId);

    //     for (uint256 i = 0; i < nextOrderId; i++) {
    //         allOrders[i] = orders[i];
    //     }

    //     return allOrders;
    // }

    function getAllOrdersOne() external view returns(OrderInfo[] memory){
        return orderList;
    }

    function withdrawCommisionFromContract() public onlyOwner {
         //transfer all commision to the address which called it
    }

    function pause() external onlyOwner {
     _pause();
    }
 
    function unpause() external onlyOwner {
     _unpause();
    }

    function getAvailableMarketplaceTokens() external view returns(uint256) {
        return slvToken.balanceOf(address(this));
    }

    
}

    

   


