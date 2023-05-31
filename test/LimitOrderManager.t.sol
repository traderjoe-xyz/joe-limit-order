// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract TestLimitOrderManager is TestHelper {
    function test_Name() public {
        assertEq(limitOrderManager.name(), "Joe Limit Order Manager", "test_Name::1");
    }

    function test_GetFactory() public {
        assertEq(address(limitOrderManager.getFactory()), address(lbFactory), "test_GetFactory::1");
    }

    function test_GettersForBidOrder() public {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        deal(address(tokenY), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, address(this));

        assertEq(order.positionId, 1, "test_GettersForBidOrder::1");

        uint256 lbLiquidity = lbPair.balanceOf(address(limitOrderManager), bidId);

        assertGt(lbLiquidity, 0, "test_GettersForBidOrder::2");
        assertEq(order.liquidity, lbLiquidity, "test_GettersForBidOrder::3");

        uint256 positionOrderId =
            limitOrderManager.getLastPositionId(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(positionOrderId, 1, "test_GettersForBidOrder::4");

        ILimitOrderManager.Position memory position = limitOrderManager.getPosition(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, positionOrderId
        );

        assertEq(position.liquidity, lbLiquidity, "test_GettersForBidOrder::5");
        assertEq(position.amount, 0, "test_GettersForBidOrder::6");
        assertFalse(position.withdrawn, "test_GettersForBidOrder::7");

        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId),
            "test_GettersForBidOrder::8"
        );

        (uint256 amountX, uint256 amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        assertEq(amountX, 0, "test_GettersForBidOrder::9");
        assertApproxEqAbs(amountY, 1e18, 1, "test_GettersForBidOrder::10");

        (amountX, amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, 1, address(this)
        );

        assertEq(amountX, 0, "test_GettersForBidOrder::11");
        assertEq(amountY, 0, "test_GettersForBidOrder::12");
    }

    function test_GettersForAskOrder() public {
        uint24 activeId = activeId();

        uint24 askId = activeId + 1;

        deal(address(tokenX), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, address(this));

        assertEq(order.positionId, 1, "test_GettersForAskOrder::1");

        uint256 lbLiquidity = lbPair.balanceOf(address(limitOrderManager), askId);

        assertGt(lbLiquidity, 0, "test_GettersForAskOrder::2");
        assertEq(order.liquidity, lbLiquidity, "test_GettersForAskOrder::3");

        uint256 positionOrderId =
            limitOrderManager.getLastPositionId(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(positionOrderId, 1, "test_GettersForAskOrder::4");

        ILimitOrderManager.Position memory position = limitOrderManager.getPosition(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, positionOrderId
        );

        assertEq(position.liquidity, lbLiquidity, "test_GettersForAskOrder::5");
        assertEq(position.amount, 0, "test_GettersForAskOrder::6");
        assertEq(position.withdrawn, false, "test_GettersForAskOrder::7");

        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId),
            "test_GettersForAskOrder::8"
        );

        (uint256 amountX, uint256 amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        assertApproxEqAbs(amountX, 1e18, 1, "test_GettersForAskOrder::9");
        assertEq(amountY, 0, "test_GettersForAskOrder::10");

        (amountX, amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, 1, address(this)
        );

        assertEq(amountX, 0, "test_GettersForAskOrder::11");
        assertEq(amountY, 0, "test_GettersForAskOrder::12");
    }

    function test_revert_Getters() external {
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.getOrder(tokenX, tokenX, binStep, ILimitOrderManager.OrderType.BID, 1, address(this));

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.getOrder(tokenX, tokenY, 1000, ILimitOrderManager.OrderType.BID, 1, address(this));

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidTokenOrder.selector);
        limitOrderManager.getOrder(tokenY, tokenX, binStep, ILimitOrderManager.OrderType.BID, 1, address(this));
    }

    function test_PlaceMultipleOrderForBidOrder() external {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        deal(address(tokenY), address(this), 3e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0, 1e18);

        uint256 lbLiquidity0BeforeSecond = lbPair.balanceOf(address(limitOrderManager), bidId0);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0, 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId1, 1e18);

        uint256 lbLiquidity1 = lbPair.balanceOf(address(limitOrderManager), bidId1);

        ILimitOrderManager.Order memory order0 =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0, address(this));

        ILimitOrderManager.Order memory order1 =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId1, address(this));

        assertEq(order0.positionId, 1, "test_PlaceMultipleOrderForBidOrder::1");
        assertEq(order1.positionId, 1, "test_PlaceMultipleOrderForBidOrder::2");

        uint256 positionOrderId0 =
            limitOrderManager.getLastPositionId(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0);
        uint256 positionOrderId1 =
            limitOrderManager.getLastPositionId(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId1);

        assertEq(positionOrderId0, 1, "test_PlaceMultipleOrderForBidOrder::3");
        assertEq(positionOrderId1, 1, "test_PlaceMultipleOrderForBidOrder::4");

        ILimitOrderManager.Position memory position0 = limitOrderManager.getPosition(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0, positionOrderId0
        );
        ILimitOrderManager.Position memory position1 = limitOrderManager.getPosition(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId1, positionOrderId1
        );

        assertEq(position0.liquidity, lbLiquidity0BeforeSecond * 2, "test_PlaceMultipleOrderForBidOrder::5");
        assertEq(position1.liquidity, lbLiquidity1, "test_PlaceMultipleOrderForBidOrder::6");

        assertEq(position0.amount, 0, "test_PlaceMultipleOrderForBidOrder::7");
        assertEq(position1.amount, 0, "test_PlaceMultipleOrderForBidOrder::8");
    }

    function test_PlaceMultipleOrderForAskOrder() external {
        uint24 activeId = activeId();

        uint24 askId0 = activeId + 1;
        uint24 askId1 = activeId + 2;

        deal(address(tokenX), address(this), 3e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0, 1e18);

        uint256 lbLiquidity0BeforeSecond = lbPair.balanceOf(address(limitOrderManager), askId0);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0, 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId1, 1e18);

        uint256 lbLiquidity1 = lbPair.balanceOf(address(limitOrderManager), askId1);

        ILimitOrderManager.Order memory order0 =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0, address(this));

        ILimitOrderManager.Order memory order1 =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId1, address(this));

        assertEq(order0.positionId, 1, "test_PlaceMultipleOrderForAskOrder::1");
        assertEq(order1.positionId, 1, "test_PlaceMultipleOrderForAskOrder::2");

        uint256 positionOrderId0 =
            limitOrderManager.getLastPositionId(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0);
        uint256 positionOrderId1 =
            limitOrderManager.getLastPositionId(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId1);

        assertEq(positionOrderId0, 1, "test_PlaceMultipleOrderForAskOrder::3");
        assertEq(positionOrderId1, 1, "test_PlaceMultipleOrderForAskOrder::4");

        ILimitOrderManager.Position memory position0 = limitOrderManager.getPosition(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0, positionOrderId0
        );
        ILimitOrderManager.Position memory position1 = limitOrderManager.getPosition(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId1, positionOrderId1
        );

        assertEq(position0.liquidity, lbLiquidity0BeforeSecond * 2, "test_PlaceMultipleOrderForAskOrder::5");
        assertEq(position1.liquidity, lbLiquidity1, "test_PlaceMultipleOrderForAskOrder::6");

        assertEq(position0.amount, 0, "test_PlaceMultipleOrderForAskOrder::7");
        assertEq(position1.amount, 0, "test_PlaceMultipleOrderForAskOrder::8");
    }

    function test_revert_PlaceOrderForBidOrder() external {
        uint24 activeId = activeId();

        // trying to place an order on the active bin
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidOrder.selector);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId, 1e18);

        // trying to place an order on the active bin + 1 (wrong side)
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidOrder.selector);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId + 1, 1e18);

        // trying to deposit 0
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAmount.selector);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1, 0);
    }

    function test_revert_PlaceOrderForAskOrder() external {
        uint24 activeId = activeId();

        // trying to place an order on the active bin
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidOrder.selector);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId, 1e18);

        // trying to place an order on the active bin - 1 (wrong side)
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidOrder.selector);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId - 1, 1e18);

        // trying to deposit 0
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAmount.selector);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1, 0);
    }

    function test_CancelOrderForBidOrder() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        deal(address(tokenY), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        uint256 lbLiquidity = lbPair.balanceOf(address(limitOrderManager), bidId);
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(bidId);
        uint256 totalSupply = lbPair.totalSupply(bidId);

        (uint256 amountX, uint256 amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(lbPair.balanceOf(address(limitOrderManager), bidId), 0, "test_CancelOrderForBidOrder::1");

        assertEq(amountX, 0, "test_CancelOrderForBidOrder::2");
        assertApproxEqAbs(amountY, 1e18, 1, "test_CancelOrderForBidOrder::3");

        assertEq(tokenX.balanceOf(address(this)), amountX, "test_CancelOrderForBidOrder::4");
        assertEq(tokenY.balanceOf(address(this)), amountY, "test_CancelOrderForBidOrder::5");

        assertEq(lbLiquidity * binReserveX / totalSupply, amountX, "test_CancelOrderForBidOrder::6");
        assertEq(lbLiquidity * binReserveY / totalSupply, amountY, "test_CancelOrderForBidOrder::7");
    }

    function test_CancelOrderForAskOrder() external {
        uint24 activeId = activeId();

        uint24 askId = activeId + 1;

        deal(address(tokenX), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        uint256 lbLiquidity = lbPair.balanceOf(address(limitOrderManager), askId);
        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(askId);
        uint256 totalSupply = lbPair.totalSupply(askId);

        (uint256 amountX, uint256 amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(lbPair.balanceOf(address(limitOrderManager), askId), 0, "test_CancelOrderForAskOrder::1");

        assertApproxEqAbs(amountX, 1e18, 1, "test_CancelOrderForAskOrder::2");
        assertEq(amountY, 0, "test_CancelOrderForAskOrder::3");

        assertEq(tokenX.balanceOf(address(this)), amountX, "test_CancelOrderForAskOrder::4");
        assertEq(tokenY.balanceOf(address(this)), amountY, "test_CancelOrderForAskOrder::5");

        assertEq(lbLiquidity * binReserveX / totalSupply, amountX, "test_CancelOrderForAskOrder::6");
        assertEq(lbLiquidity * binReserveY / totalSupply, amountY, "test_CancelOrderForAskOrder::7");
    }

    function test_revert_CancelOrderForBidOrder() external {
        uint24 activeId = activeId();

        // trying to cancel an order that doesn't exist
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId);

        deal(address(tokenY), address(this), 3e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1, 1e18);

        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1);

        // trying to cancel an order that was already cancelled
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1);

        limitOrderManager.placeOrder(wnative, usdc, 20, ILimitOrderManager.OrderType.ASK, activeId + 1, 1e18);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAddress.selector);
        limitOrderManager.cancelOrder(IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, activeId + 1);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1, 1e18);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAddress.selector);
        limitOrderManager.cancelOrder(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, activeId - 1
        );

        swapNbBins(true, 2);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1);

        // trying to cancel an order that was already executed
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderAlreadyExecuted.selector);
        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId - 1);
    }

    function test_revert_CancelOrderForAskOrder() external {
        uint24 activeId = activeId();

        // trying to cancel an order that doesn't exist
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId);

        deal(address(tokenX), address(this), 2e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1, 1e18);

        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1);

        // trying to cancel an order that was already cancelled
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1, 1e18);

        swapNbBins(false, 2);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1);

        // trying to cancel an order that was already executed
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderAlreadyExecuted.selector);
        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId + 1);
    }

    function test_ExecuteOrderForBidOrder() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        deal(address(tokenY), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        (uint256 amountX, uint256 amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        uint256 price = lbPair.getPriceFromId(bidId);

        assertEq(amountX, 0, "test_ExecuteOrderForBidOrder::1");
        assertApproxEqAbs(amountY, 1e18, 1, "test_ExecuteOrderForBidOrder::2");

        swapNbBins(true, 2);

        (amountX, amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        uint256 fullySwapped = (1e18 << 128) / price;

        assertApproxEqRel(amountX, fullySwapped, 1e15, "test_ExecuteOrderForBidOrder::3");
        assertEq(amountY, 0, "test_ExecuteOrderForBidOrder::4");

        // amount is greater cause the fees are compounded
        assertGt(amountX, fullySwapped, "test_ExecuteOrderForBidOrder::5");

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        (uint256 executedAmountX, uint256 executedAmountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        assertEq(executedAmountX, amountX, "test_ExecuteOrderForBidOrder::6");
        assertEq(executedAmountY, amountY, "test_ExecuteOrderForBidOrder::7");
    }

    function test_ExecuteOrderForAskOrder() external {
        uint24 activeId = activeId();

        uint24 askId = activeId + 1;

        deal(address(tokenX), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        (uint256 amountX, uint256 amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        uint256 price = lbPair.getPriceFromId(askId);

        assertApproxEqAbs(amountX, 1e18, 1, "test_ExecuteOrderForAskOrder::1");
        assertEq(amountY, 0, "test_ExecuteOrderForAskOrder::2");

        swapNbBins(false, 2);

        (amountX, amountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        uint256 fullySwapped = (price * 1e18) >> 128;

        assertEq(amountX, 0, "test_ExecuteOrderForAskOrder::3");
        assertApproxEqRel(amountY, fullySwapped, 1e15, "test_ExecuteOrderForAskOrder::4");

        // amount is greater cause the fees are compounded
        assertGt(amountY, fullySwapped, "test_ExecuteOrderForAskOrder::5");

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        (uint256 executedAmountX, uint256 executedAmountY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        assertEq(executedAmountX, amountX, "test_ExecuteOrderForAskOrder::6");
        assertEq(executedAmountY, amountY, "test_ExecuteOrderForAskOrder::7");
    }

    function test_revert_ExecuteOrders() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;
        uint24 askId = activeId + 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, activeId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, activeId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__NoOrdersToExecute.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, askId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__NoOrdersToExecute.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, bidId);

        deal(address(tokenY), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        deal(address(tokenX), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        swapNbBins(true, 2);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAddress.selector);
        limitOrderManager.executeOrders(tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, bidId);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrdersAlreadyExecuted.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        swapNbBins(false, 4);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrdersAlreadyExecuted.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        swapNbBins(true, 2);

        deal(address(tokenY), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        deal(address(tokenX), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        limitOrderManager.cancelOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        swapNbBins(true, 2);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroPositionLiquidity.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        swapNbBins(false, 4);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroPositionLiquidity.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);
    }

    function test_ClaimOrderForBidOrder() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        vm.startPrank(alice);
        deal(address(tokenY), alice, 1e18);
        tokenY.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);
        vm.stopPrank();

        swapNbBins(true, 2);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        (uint256 amountX, uint256 amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        vm.prank(alice);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(tokenX.balanceOf(alice), amountX, "test_ClaimOrderForBidOrder::1");
        assertEq(tokenY.balanceOf(alice), amountY, "test_ClaimOrderForBidOrder::2");

        (amountX, amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(amountX, 0, "test_ClaimOrderForBidOrder::3");
        assertEq(amountY, 0, "test_ClaimOrderForBidOrder::4");

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(order.positionId, 0, "test_ClaimOrderForBidOrder::5");
        assertEq(order.liquidity, 0, "test_ClaimOrderForBidOrder::6");
    }

    function test_ClaimOrderForAskOrder() external {
        uint24 activeId = activeId();

        uint24 askId = activeId + 1;

        vm.startPrank(alice);
        deal(address(tokenX), alice, 1e18);
        tokenX.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);
        vm.stopPrank();

        swapNbBins(false, 2);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        (uint256 amountX, uint256 amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        vm.prank(alice);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(tokenX.balanceOf(alice), amountX, "test_ClaimOrderForAskOrder::1");
        assertEq(tokenY.balanceOf(alice), amountY, "test_ClaimOrderForAskOrder::2");

        (amountX, amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(amountX, 0, "test_ClaimOrderForAskOrder::3");
        assertEq(amountY, 0, "test_ClaimOrderForAskOrder::4");

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(order.positionId, 0, "test_ClaimOrderForAskOrder::5");
        assertEq(order.liquidity, 0, "test_ClaimOrderForAskOrder::6");
    }

    function test_revert_ClaimOrder() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;
        uint24 askId = activeId + 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotClaimable.selector);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotClaimable.selector);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        deal(address(tokenY), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        deal(address(tokenX), address(this), 1e18);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);
    }

    function test_ExecuteOnClaimForBidOrder() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        vm.startPrank(alice);
        deal(address(tokenY), alice, 1e18);
        tokenY.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);
        vm.stopPrank();

        uint256 liquidity = lbPair.balanceOf(address(limitOrderManager), bidId);

        swapNbBins(true, 2);

        (uint256 amountX, uint256 amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        vm.prank(alice);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(tokenX.balanceOf(alice), amountX, "test_ExecuteOnClaimForBidOrder::1");
        assertEq(tokenY.balanceOf(alice), amountY, "test_ExecuteOnClaimForBidOrder::2");

        (uint256 amountXAfter, uint256 amountYAfter) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(amountXAfter, 0, "test_ExecuteOnClaimForBidOrder::3");
        assertEq(amountYAfter, 0, "test_ExecuteOnClaimForBidOrder::4");

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(order.positionId, 0, "test_ExecuteOnClaimForBidOrder::5");
        assertEq(order.liquidity, 0, "test_ExecuteOnClaimForBidOrder::6");

        ILimitOrderManager.Position memory position =
            limitOrderManager.getPosition(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1);

        assertEq(position.liquidity, liquidity, "test_ExecuteOnClaimForBidOrder::7");
        assertEq(position.amount, amountX, "test_ExecuteOnClaimForBidOrder::8");
        assertEq(position.withdrawn, true, "test_ExecuteOnClaimForBidOrder::9");

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrdersAlreadyExecuted.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);
    }

    function test_ExecuteOnClaimForAskOrder() external {
        uint24 activeId = activeId();

        uint24 askId = activeId + 1;

        vm.startPrank(alice);
        deal(address(tokenX), alice, 1e18);
        tokenX.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);
        vm.stopPrank();

        uint256 liquidity = lbPair.balanceOf(address(limitOrderManager), askId);

        swapNbBins(false, 2);

        (uint256 amountX, uint256 amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        vm.prank(alice);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(tokenX.balanceOf(alice), amountX, "test_ExecuteOnClaimForAskOrder::1");
        assertEq(tokenY.balanceOf(alice), amountY, "test_ExecuteOnClaimForAskOrder::2");

        (uint256 amountXAfter, uint256 amountYAfter) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(amountXAfter, 0, "test_ExecuteOnClaimForAskOrder::3");
        assertEq(amountYAfter, 0, "test_ExecuteOnClaimForAskOrder::4");

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(order.positionId, 0, "test_ExecuteOnClaimForAskOrder::5");
        assertEq(order.liquidity, 0, "test_ExecuteOnClaimForAskOrder::6");

        ILimitOrderManager.Position memory position =
            limitOrderManager.getPosition(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1);

        assertEq(position.liquidity, liquidity, "test_ExecuteOnClaimForAskOrder::7");
        assertEq(position.amount, amountY, "test_ExecuteOnClaimForAskOrder::8");
        assertEq(position.withdrawn, true, "test_ExecuteOnClaimForAskOrder::9");

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrdersAlreadyExecuted.selector);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);
    }

    function test_ClaimOnPlaceOrderForBidOrder() external {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        vm.startPrank(alice);
        deal(address(tokenY), alice, 2e18);
        tokenY.approve(address(limitOrderManager), 2e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);
        vm.stopPrank();

        (uint256 amountX, uint256 amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        swapNbBins(true, 2);

        (uint256 amountXAfter, uint256 amountYAfter) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        swapNbBins(false, 2);

        vm.prank(alice);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        (uint256 amountXAfter2, uint256 amountYAfter2) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(amountXAfter2, amountX, "test_ClaimOnPlaceOrderForBidOrder::1");
        assertEq(amountYAfter2, amountY, "test_ClaimOnPlaceOrderForBidOrder::2");

        assertEq(tokenX.balanceOf(alice), amountXAfter, "test_ClaimOnPlaceOrderForBidOrder::3");
        assertEq(tokenY.balanceOf(alice), amountYAfter, "test_ClaimOnPlaceOrderForBidOrder::4");

        swapNbBins(true, 2);

        vm.prank(alice);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(tokenX.balanceOf(alice), 2 * amountXAfter, "test_ClaimOnPlaceOrderForBidOrder::5");
        assertEq(tokenY.balanceOf(alice), 2 * amountYAfter, "test_ClaimOnPlaceOrderForBidOrder::6");
    }

    function test_ClaimOnPlaceOrderForAskOrder() public {
        uint24 activeId = activeId();

        uint24 askId = activeId + 1;

        vm.startPrank(alice);
        deal(address(tokenX), alice, 2e18);
        tokenX.approve(address(limitOrderManager), 2e18);

        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);
        vm.stopPrank();

        (uint256 amountX, uint256 amountY) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        swapNbBins(false, 2);

        (uint256 amountXAfter, uint256 amountYAfter) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        swapNbBins(true, 2);

        vm.prank(alice);
        limitOrderManager.placeOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        (uint256 amountXAfter2, uint256 amountYAfter2) =
            limitOrderManager.getCurrentAmounts(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(amountXAfter2, amountX, "test_ClaimOnPlaceOrderForAskOrder::1");
        assertEq(amountYAfter2, amountY, "test_ClaimOnPlaceOrderForAskOrder::2");

        assertEq(tokenX.balanceOf(alice), amountXAfter, "test_ClaimOnPlaceOrderForAskOrder::3");
        assertEq(tokenY.balanceOf(alice), amountYAfter, "test_ClaimOnPlaceOrderForAskOrder::4");

        swapNbBins(false, 2);

        vm.prank(alice);
        limitOrderManager.claimOrder(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(tokenX.balanceOf(alice), 2 * amountXAfter, "test_ClaimOnPlaceOrderForAskOrder::5");
        assertEq(tokenY.balanceOf(alice), 2 * amountYAfter, "test_ClaimOnPlaceOrderForAskOrder::6");
    }

    function test_BatchOrdersForBidOrders() external {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;
        uint24 bidId2 = activeId - 3;
        uint24 bidId3 = activeId - 4;

        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](4);

        params[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId2,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId3,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(tokenY), alice, 4e18);
        tokenY.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrders(params);
        vm.stopPrank();

        swapNbBins(true, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0),
            "test_BatchOrdersForBidOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId1),
            "test_BatchOrdersForBidOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId2),
            "test_BatchOrdersForBidOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId3),
            "test_BatchOrdersForBidOrders::4"
        );

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](2);

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1
        });

        vm.prank(alice);
        limitOrderManager.batchExecuteOrders(orderParams);

        // Reset alice's balance
        deal(address(tokenX), alice, 0);
        deal(address(tokenY), alice, 0);

        (uint256 amountX2, uint256 amountY2) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId2, alice
        );

        assertGt(amountX2, 0, "test_BatchOrdersForBidOrders::5");
        assertGt(amountY2, 0, "test_BatchOrdersForBidOrders::6");

        (uint256 amountX3, uint256 amountY3) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId3, alice
        );

        assertEq(amountX3, 0, "test_BatchOrdersForBidOrders::7");
        assertGt(amountY3, 0, "test_BatchOrdersForBidOrders::8");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId2
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId3
        });

        vm.prank(alice);
        limitOrderManager.batchCancelOrders(orderParams);

        assertEq(tokenX.balanceOf(alice), amountX2 + amountX3, "test_BatchOrdersForBidOrders::9");
        assertEq(tokenY.balanceOf(alice), amountY2 + amountY3, "test_BatchOrdersForBidOrders::10");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1
        });

        vm.prank(alice);
        limitOrderManager.batchClaimOrders(orderParams);

        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            tokenX.balanceOf(alice), 4 * amountX2 + amountX2 + amountX3, 1e16, "test_BatchOrdersForBidOrders::11"
        );
        assertEq(tokenY.balanceOf(alice), amountY2 + amountY3, "test_BatchOrdersForBidOrders::12");
    }

    function test_BatchOrdersForAskOrders() public {
        uint24 activeId = activeId();

        uint24 askId0 = activeId + 1;
        uint24 askId1 = activeId + 2;
        uint24 askId2 = activeId + 3;
        uint24 askId3 = activeId + 4;

        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](4);

        params[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId2,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId3,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(tokenX), alice, 4e18);
        tokenX.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrders(params);
        vm.stopPrank();

        swapNbBins(false, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0),
            "test_BatchOrdersForAskOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId1),
            "test_BatchOrdersForAskOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId2),
            "test_BatchOrdersForAskOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId3),
            "test_BatchOrdersForAskOrders::4"
        );

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](2);

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1
        });

        vm.prank(alice);
        limitOrderManager.batchExecuteOrders(orderParams);

        // Reset alice's balance
        deal(address(tokenX), alice, 0);
        deal(address(tokenY), alice, 0);

        (uint256 amountX2, uint256 amountY2) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId2, alice
        );

        assertGt(amountX2, 0, "test_BatchOrdersForAskOrders::5");
        assertGt(amountY2, 0, "test_BatchOrdersForAskOrders::6");

        (uint256 amountX3, uint256 amountY3) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId3, alice
        );

        assertGt(amountX3, 0, "test_BatchOrdersForAskOrders::7");
        assertEq(amountY3, 0, "test_BatchOrdersForAskOrders::8");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId2
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId3
        });

        vm.prank(alice);
        limitOrderManager.batchCancelOrders(orderParams);

        assertEq(tokenX.balanceOf(alice), amountX2 + amountX3, "test_BatchOrdersForAskOrders::9");
        assertEq(tokenY.balanceOf(alice), amountY2 + amountY3, "test_BatchOrdersForAskOrders::10");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1
        });

        vm.prank(alice);
        limitOrderManager.batchClaimOrders(orderParams);

        assertEq(tokenX.balanceOf(alice), amountX2 + amountX3, "test_BatchOrdersForAskOrders::11");
        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            tokenY.balanceOf(alice), 4 * amountY2 + amountY2 + amountY3, 1e16, "test_BatchOrdersForAskOrders::12"
        );
    }

    function test_revert_BatchOrders() public {
        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](0);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchPlaceOrders(params);

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](0);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchExecuteOrders(orderParams);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchCancelOrders(orderParams);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchClaimOrders(orderParams);
    }

    function test_BatchOrdersSamePairForBidOrders() public {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;
        uint24 bidId2 = activeId - 3;
        uint24 bidId3 = activeId - 4;

        ILimitOrderManager.PlaceOrderParamsSamePair[] memory params =
            new ILimitOrderManager.PlaceOrderParamsSamePair[](4);

        params[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId2,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId3,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(tokenY), alice, 4e18);
        tokenY.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrdersSamePair(tokenX, tokenY, binStep, params);
        vm.stopPrank();

        swapNbBins(true, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId0),
            "test_BatchOrdersForBidOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId1),
            "test_BatchOrdersForBidOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId2),
            "test_BatchOrdersForBidOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId3),
            "test_BatchOrdersForBidOrders::4"
        );

        ILimitOrderManager.OrderParamsSamePair[] memory orderParams = new ILimitOrderManager.OrderParamsSamePair[](2);

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId1});

        vm.prank(alice);
        limitOrderManager.batchExecuteOrdersSamePair(tokenX, tokenY, binStep, orderParams);

        // Reset alice's balance
        deal(address(tokenX), alice, 0);
        deal(address(tokenY), alice, 0);

        (uint256 amountX2, uint256 amountY2) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId2, alice
        );

        assertGt(amountX2, 0, "test_BatchOrdersForBidOrders::5");
        assertGt(amountY2, 0, "test_BatchOrdersForBidOrders::6");

        (uint256 amountX3, uint256 amountY3) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId3, alice
        );

        assertEq(amountX3, 0, "test_BatchOrdersForBidOrders::7");
        assertGt(amountY3, 0, "test_BatchOrdersForBidOrders::8");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId2});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId3});

        vm.prank(alice);
        limitOrderManager.batchCancelOrdersSamePair(tokenX, tokenY, binStep, orderParams);

        assertEq(tokenX.balanceOf(alice), amountX2 + amountX3, "test_BatchOrdersForBidOrders::9");
        assertEq(tokenY.balanceOf(alice), amountY2 + amountY3, "test_BatchOrdersForBidOrders::10");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId1});

        vm.prank(alice);
        limitOrderManager.batchClaimOrdersSamePair(tokenX, tokenY, binStep, orderParams);

        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            tokenX.balanceOf(alice), 4 * amountX2 + amountX2 + amountX3, 1e16, "test_BatchOrdersForBidOrders::11"
        );
        assertEq(tokenY.balanceOf(alice), amountY2 + amountY3, "test_BatchOrdersForBidOrders::12");
    }

    function test_BatchOrdersSamePairForAskOrders() public {
        uint24 activeId = activeId();

        uint24 askId0 = activeId + 1;
        uint24 askId1 = activeId + 2;
        uint24 askId2 = activeId + 3;
        uint24 askId3 = activeId + 4;

        ILimitOrderManager.PlaceOrderParamsSamePair[] memory params =
            new ILimitOrderManager.PlaceOrderParamsSamePair[](4);

        params[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId2,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId3,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(tokenX), alice, 4e18);
        tokenX.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrdersSamePair(tokenX, tokenY, binStep, params);
        vm.stopPrank();

        swapNbBins(false, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId0),
            "test_BatchOrdersForAskOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId1),
            "test_BatchOrdersForAskOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId2),
            "test_BatchOrdersForAskOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId3),
            "test_BatchOrdersForAskOrders::4"
        );

        ILimitOrderManager.OrderParamsSamePair[] memory orderParams = new ILimitOrderManager.OrderParamsSamePair[](2);

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId1});

        vm.prank(alice);
        limitOrderManager.batchExecuteOrdersSamePair(tokenX, tokenY, binStep, orderParams);

        // Reset alice's balance
        deal(address(tokenX), alice, 0);
        deal(address(tokenY), alice, 0);

        (uint256 amountX2, uint256 amountY2) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId2, alice
        );

        assertGt(amountX2, 0, "test_BatchOrdersForAskOrders::5");
        assertGt(amountY2, 0, "test_BatchOrdersForAskOrders::6");

        (uint256 amountX3, uint256 amountY3) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.ASK, askId3, alice
        );

        assertGt(amountX3, 0, "test_BatchOrdersForAskOrders::7");
        assertEq(amountY3, 0, "test_BatchOrdersForAskOrders::8");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId2});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId3});

        vm.prank(alice);
        limitOrderManager.batchCancelOrdersSamePair(tokenX, tokenY, binStep, orderParams);

        assertEq(tokenX.balanceOf(alice), amountX2 + amountX3, "test_BatchOrdersForAskOrders::9");
        assertEq(tokenY.balanceOf(alice), amountY2 + amountY3, "test_BatchOrdersForAskOrders::10");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId1});

        vm.prank(alice);
        limitOrderManager.batchClaimOrdersSamePair(tokenX, tokenY, binStep, orderParams);

        assertEq(tokenX.balanceOf(alice), amountX2 + amountX3, "test_BatchOrdersForAskOrders::11");
        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            tokenY.balanceOf(alice), 4 * amountY2 + amountY2 + amountY3, 1e16, "test_BatchOrdersForAskOrders::12"
        );
    }

    function test_PlaceOrderNative() public {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;

        assertEq(address(tokenY), address(wnative), "test_PlaceOrderNative::1");

        limitOrderManager.placeOrder{value: 1e18}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxusdc.getActiveId() + 1, 1e18
        );

        uint256 balanceBefore = address(this).balance;

        limitOrderManager.placeOrder{value: 1e18 + 1}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        assertEq(address(this).balance, balanceBefore - 1e18, "test_PlaceOrderNative::2");

        balanceBefore = address(this).balance;

        limitOrderManager.placeOrder{value: 1e18 + 1}(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxusdc.getActiveId() + 1, 1e18
        );

        assertEq(address(this).balance, balanceBefore - 1e18, "test_PlaceOrderNative::3");
    }

    function test_PlaceOrderNative_revert() public {
        uint24 activeId = activeId();

        uint24 bidId = activeId - 1;
        uint24 askId = activeId + 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18 - 1}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        uint24 avaxUsdcBidId = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair.getActiveId() - 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.BID, avaxUsdcBidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), wnative, binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            wnative, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), wnative, binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            wnative, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), IERC20(address(0)), binStep, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );
    }

    function test_BatchPlaceOrdersNative() public {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        assertEq(address(tokenY), address(wnative), "test_BatchPlaceOrdersNative::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        uint24 askId0 = wavaxusdc.getActiveId() + 1;
        uint24 askId1 = wavaxusdc.getActiveId() + 2;

        ILimitOrderManager.PlaceOrderParams[] memory orderParams = new ILimitOrderManager.PlaceOrderParams[](2);

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: IERC20(address(0)),
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: IERC20(address(0)),
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrders{value: 2e18}(orderParams);

        uint256 balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrders{value: 2e18 + 1}(orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersNative::2");

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrders{value: 2e18}(orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrders{value: 2e18 + 1}(orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersNative::3");

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: IERC20(address(0)),
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrders{value: 2e18}(orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrders{value: 2e18 + 1}(orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersNative::4");

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: IERC20(address(0)),
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrders{value: 2e18}(orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrders{value: 2e18 + 1}(orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersNative::4");

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.batchPlaceOrders{value: 1e18}(orderParams);
    }

    function test_BatchPlaceOrders_revert() public {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;

        assertEq(address(tokenY), address(wnative), "test_BatchPlaceOrdersNative::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        uint24 askId0 = wavaxusdc.getActiveId() + 1;

        ILimitOrderManager.PlaceOrderParams[] memory orderParams = new ILimitOrderManager.PlaceOrderParams[](2);

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: IERC20(address(0)),
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.batchPlaceOrders{value: 2e18 - 1}(orderParams);

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        deal(address(wnative), address(this), 1e18);
    }

    function test_BatchPlaceOrdersSamePairNative() public {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        assertEq(address(tokenY), address(wnative), "test_BatchPlaceOrdersSamePairNative::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        uint24 askId0 = wavaxusdc.getActiveId() + 1;
        uint24 askId1 = wavaxusdc.getActiveId() + 2;

        ILimitOrderManager.PlaceOrderParamsSamePair[] memory orderParams =
            new ILimitOrderManager.PlaceOrderParamsSamePair[](2);

        orderParams[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18}(tokenX, IERC20(address(0)), binStep, orderParams);

        uint256 balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 + 1}(tokenX, IERC20(address(0)), binStep, orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersSamePairNative::2");

        orderParams[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18}(IERC20(address(0)), usdc, 20, orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 + 1}(IERC20(address(0)), usdc, 20, orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersSamePairNative::3");
    }

    function test_BatchPlaceOrdersSamePair_revert() public {
        uint24 activeId = activeId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        assertEq(address(tokenY), address(wnative), "test_BatchPlaceOrdersSamePair_revert::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        uint24 askId0 = wavaxusdc.getActiveId() + 1;
        uint24 askId1 = wavaxusdc.getActiveId() + 2;

        ILimitOrderManager.PlaceOrderParamsSamePair[] memory orderParams =
            new ILimitOrderManager.PlaceOrderParamsSamePair[](2);

        orderParams[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 - 1}(tokenX, IERC20(address(0)), binStep, orderParams);

        orderParams[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1,
            amount: 1e18
        });

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 - 1}(IERC20(address(0)), usdc, 20, orderParams);
    }

    function test_ClaimOrderNative() public {
        ILBPair wavaxUsdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        uint24 wavaxUsdcActiveId = wavaxUsdc.getActiveId();
        uint24 linkWavaxActiveId = activeId();

        uint24 wavaxUsdcAskId = wavaxUsdcActiveId + 1;

        uint24 linkWavaxBidId = linkWavaxActiveId - 1;

        limitOrderManager.placeOrder{value: 1e18}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId, 1e18
        );

        swapNbBins(lbPair, true, 2);

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId);

        uint256 balanceBefore = address(this).balance;
        uint256 wnativeBalanceBefore = wnative.balanceOf(address(this));

        (uint256 claimableX, uint256 claimableY) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId, address(this)
        );

        limitOrderManager.claimOrder(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId
        );

        assertEq(claimableX, 0, "test_ClaimOrderNative::1");
        assertGt(address(this).balance, balanceBefore, "test_ClaimOrderNative::2");
        assertEq(address(this).balance, balanceBefore + claimableY, "test_ClaimOrderNative::3");
        assertEq(wnative.balanceOf(address(this)), wnativeBalanceBefore, "test_ClaimOrderNative::4");

        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId, 1e18
        );

        swapNbBins(wavaxUsdc, false, 2);

        limitOrderManager.executeOrders(wnative, usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId);

        balanceBefore = address(this).balance;
        wnativeBalanceBefore = wnative.balanceOf(address(this));

        (claimableX, claimableY) = limitOrderManager.getCurrentAmounts(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId, address(this)
        );

        limitOrderManager.claimOrder(IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId);

        assertEq(claimableY, 0, "test_ClaimOrderNative::5");
        assertGt(address(this).balance, balanceBefore, "test_ClaimOrderNative::6");
        assertEq(address(this).balance, balanceBefore + claimableX, "test_ClaimOrderNative::7");
        assertEq(wnative.balanceOf(address(this)), wnativeBalanceBefore, "test_ClaimOrderNative::8");
    }

    function test_BatchClaimOrdersNative() public {
        ILBPair wavaxUsdc = lbFactory.getLBPairInformation(wnative, usdc, 20).LBPair;

        uint24 linkWavaxBidId = activeId() - 1;
        uint24 wavaxUsdcAskId = wavaxUsdc.getActiveId() + 1;

        limitOrderManager.placeOrder{value: 1e18}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId, 1e18
        );
        limitOrderManager.placeOrder{value: 1e18}(
            tokenX, IERC20(address(0)), binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId - 1, 1e18
        );
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId, 1e18
        );
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId + 1, 1e18
        );

        swapNbBins(lbPair, true, 3);
        swapNbBins(wavaxUsdc, false, 3);

        (, uint256 lwClaimableY1) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId, address(this)
        );

        (, uint256 lwClaimableY2) = limitOrderManager.getCurrentAmounts(
            tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId - 1, address(this)
        );

        (uint256 wuClaimableX1,) = limitOrderManager.getCurrentAmounts(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId, address(this)
        );

        (uint256 wuClaimableX2,) = limitOrderManager.getCurrentAmounts(
            IERC20(address(0)), usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId + 1, address(this)
        );

        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId);
        limitOrderManager.executeOrders(tokenX, tokenY, binStep, ILimitOrderManager.OrderType.BID, linkWavaxBidId - 1);
        limitOrderManager.executeOrders(wnative, usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId);
        limitOrderManager.executeOrders(wnative, usdc, 20, ILimitOrderManager.OrderType.ASK, wavaxUsdcAskId + 1);

        uint256 balanceBefore = address(this).balance;
        uint256 wnativeBalanceBefore = wnative.balanceOf(address(this));

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](4);

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: IERC20(address(0)),
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: linkWavaxBidId
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: tokenX,
            tokenY: tokenY,
            binStep: binStep,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: linkWavaxBidId - 1
        });

        orderParams[2] = ILimitOrderManager.OrderParams({
            tokenX: wnative,
            tokenY: tokenY,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: wavaxUsdcAskId
        });

        orderParams[3] = ILimitOrderManager.OrderParams({
            tokenX: IERC20(address(0)),
            tokenY: tokenY,
            binStep: 20,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: wavaxUsdcAskId + 1
        });

        limitOrderManager.batchClaimOrders(orderParams);

        assertEq(address(this).balance, balanceBefore + lwClaimableY1 + wuClaimableX2, "test_BatchClaimOrdersNative::1");
        assertEq(
            wnative.balanceOf(address(this)),
            wnativeBalanceBefore + lwClaimableY2 + wuClaimableX1,
            "test_BatchClaimOrdersNative::2"
        );
    }

    receive() external payable {}
}
