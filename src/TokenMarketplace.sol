// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.34;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {OrderInfo} from "./types/Trade.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenMarketplace is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 immutable slvToken;

    uint256 private constant TOKEN_PRICE = 1 ether;
    uint256 private reseverdOrderedTokens;
    uint256 private nextOrderId;

    mapping(uint256 => OrderInfo) private orders;

    OrderInfo[] private orderList;

    error TokenMarketplace_ZeroNumberOfTokens(uint256 numberOfTokens);
    error TokenMarketplace_InsufficientEthPayment(uint256 expectedPayment, uint256 actualPayment);
    error TokenMarketplace_InsufficientTokenBalance(uint256 expectedToken, uint256 actualToken);
    error TokenMarketplace_InsufficientAllowance(uint256 allowedTokens, uint256 tokensToTransfer);
    error TokenMarketplace_OrderIsNotActive(uint256 orderId);
    error TokenMarketplace_NotEnoughTokensInOrder(uint256 expectedTokens, uint256 actualTokens);
    error TokenMarketplace_EthTransferFailed();
    error TokenMarketplace_InvalidOrderId();
    error TokenMarketplace_UnauthorizedSeller(address caller, uint256 orderId);
    error TokenMarkeplace_InvalidOwner();

    event buyTokens(address indexed buyer, uint256 indexed numberOfTokensBought);
    event SellOrderCreated(uint256 indexed orderId, address indexed seller, uint256 indexed numberOfTokensToSell);
    event SellOrderCancelled(uint256 indexed orderId, address indexed seller, uint256 indexed numberOfTokensCancelled);
    event BuyTokensFromSellOrderCreated(
        uint256 indexed orderId, address indexed buyer, address indexed seller, uint256 numberOfTokensBought
    );

    constructor(address _slvToken, address _owner) Ownable(_owner) {
        slvToken = IERC20(_slvToken);
    }

    function buyTokensFromMarketplace(uint256 numberOfTokens) external payable whenNotPaused nonReentrant {
        _revertIfZeroTokenAmount(numberOfTokens);
        _revertIfIncorrectEthPayment(numberOfTokens);
        _revertIfTokenBalanceOfMarketplaceIsLow(numberOfTokens);

        slvToken.safeTransfer(msg.sender, numberOfTokens);
        
        emit buyTokens(msg.sender, numberOfTokens);
    }

    function _revertIfTokenBalanceOfMarketplaceIsLow(uint256 numberOfTokens) internal view {
         if (slvToken.balanceOf(address(this)) < numberOfTokens) revert TokenMarketplace_InsufficientTokenBalance(slvToken.balanceOf(address(this)), numberOfTokens);
    }
    function createSellOrder(uint256 numberOfTokensToSell) external {
        _revertIfZeroTokenAmount(numberOfTokensToSell);
        _revertIfInsufficientSellerTokenBalance(numberOfTokensToSell);
        _revertIfIAllowaneNotEnough(numberOfTokensToSell);

        OrderInfo memory order = OrderInfo({
            orderId: nextOrderId, seller: msg.sender, numberOfTokensToSell: numberOfTokensToSell, isActive: true
        });
        orders[nextOrderId] = order;
        nextOrderId++;
        slvToken.safeTransferFrom(msg.sender, address(this), numberOfTokensToSell);
        reseverdOrderedTokens += numberOfTokensToSell;
        orderList.push(order);
        
        emit SellOrderCreated(order.orderId, msg.sender, numberOfTokensToSell);
    }

    function _revertIfInsufficientSellerTokenBalance(uint256 numberOfTokens) internal view {
        uint256 tokenBalance = slvToken.balanceOf(msg.sender);
        if (numberOfTokens > tokenBalance) revert TokenMarketplace_InsufficientTokenBalance(tokenBalance, numberOfTokens);
    }

    function  _revertIfIAllowaneNotEnough(uint256 numberOfTokens) internal view {
          uint256 allowance = slvToken.allowance(msg.sender, address(this));
          if (allowance < numberOfTokens) revert TokenMarketplace_InsufficientAllowance(allowance, numberOfTokens);
    }

    function buyTokensFromSellOrderCreated(uint256 orderId, uint256 numberOfTokensToBuy)
        external
        payable
        whenNotPaused
    {
        _revertIfInvalidOrderId(orderId);
        _revertIfZeroTokenAmount(numberOfTokensToBuy);
        _revertIfIncorrectEthPayment(numberOfTokensToBuy);

        OrderInfo storage order = orders[orderId];

        if (order.isActive == false) revert TokenMarketplace_OrderIsNotActive(order.orderId);
        if (order.numberOfTokensToSell < numberOfTokensToBuy) revert TokenMarketplace_NotEnoughTokensInOrder(order.numberOfTokensToSell, numberOfTokensToBuy);
        
        order.numberOfTokensToSell -= numberOfTokensToBuy;

        if (order.numberOfTokensToSell == 0) order.isActive = false;

        slvToken.safeTransfer(msg.sender, numberOfTokensToBuy);
        (bool success,) = order.seller.call{value: msg.value}("");
        if (!success) revert TokenMarketplace_EthTransferFailed();
        emit BuyTokensFromSellOrderCreated(orderId, msg.sender, order.seller, numberOfTokensToBuy);
    }

    function _revertIfZeroTokenAmount(uint256 numberOfTokens) internal pure {
        if (numberOfTokens == 0) revert TokenMarketplace_ZeroNumberOfTokens(numberOfTokens);
    }

    function _revertIfIncorrectEthPayment(uint256 numberOfTokens) internal view {
        if (numberOfTokens * TOKEN_PRICE != msg.value) revert TokenMarketplace_InsufficientEthPayment(numberOfTokens * TOKEN_PRICE, msg.value);
    }

    function cancelSellOrder(uint256 orderId) external {
        _revertIfInvalidOrderId(orderId);
        OrderInfo storage order = orders[orderId];

        if (order.seller != msg.sender) revert TokenMarketplace_UnauthorizedSeller(msg.sender, orderId);
        order.isActive = false;
        reseverdOrderedTokens -= order.numberOfTokensToSell;
        slvToken.safeTransfer(order.seller, order.numberOfTokensToSell);
        emit SellOrderCancelled(orderId, msg.sender, order.numberOfTokensToSell);
    }

    function _revertIfInvalidOrderId(uint256 orderId) internal view {
        uint256 totalNumberOfCreatedOrder = getNumberOfCreatedOrders();
        if (orderId >= totalNumberOfCreatedOrder) revert TokenMarketplace_InvalidOrderId();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getAvailableMarketplaceTokens() external view returns (uint256) {
        return slvToken.balanceOf(address(this));
    }

    function getNumberOfCreatedOrders() public view returns (uint256) {
        return nextOrderId;
    }

    function getCreatedOrderById(uint256 orderId) external view returns (OrderInfo memory) {
        return orders[orderId];
    }

    function getAllOrders() external view returns (OrderInfo[] memory) {
        return orderList;
    }

    function getTokenPrice() external pure returns(uint256){
        return TOKEN_PRICE;
    }
}
