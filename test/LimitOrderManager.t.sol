// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "joe-v2/libraries/PriceHelper.sol";
import "./TestHelper.sol";

contract TestLimitOrderManager is TestHelper {
    function test_Name() public {
        assertEq(limitOrderManager.name(), "Joe Limit Order Manager", "test_Name::1");
    }

    function test_GetFactory() public {
        assertEq(address(limitOrderManager.getFactory()), address(lbFactory), "test_GetFactory::1");
    }

    function test_GettersForBidOrder() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this));

        assertEq(order.positionId, 1, "test_GettersForBidOrder::1");

        uint256 lbLiquidity = linkWavax.balanceOf(address(limitOrderManager), bidId);

        assertGt(lbLiquidity, 0, "test_GettersForBidOrder::2");
        assertEq(order.liquidity, lbLiquidity, "test_GettersForBidOrder::3");

        uint256 positionOrderId =
            limitOrderManager.getLastPositionId(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(positionOrderId, 1, "test_GettersForBidOrder::4");

        ILimitOrderManager.Position memory position = limitOrderManager.getPosition(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, positionOrderId
        );

        assertEq(position.liquidity, lbLiquidity, "test_GettersForBidOrder::5");
        assertEq(position.amount, 0, "test_GettersForBidOrder::6");
        assertFalse(position.withdrawn, "test_GettersForBidOrder::7");

        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId),
            "test_GettersForBidOrder::8"
        );

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        assertEq(amountX, 0, "test_GettersForBidOrder::9");
        assertApproxEqAbs(amountY, 1e18, 1, "test_GettersForBidOrder::10");
        assertEq(feeX, 0, "test_GettersForBidOrder::11");
        assertGt(feeY, 0, "test_GettersForBidOrder::12");

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, 1, address(this)
        );

        assertEq(amountX, 0, "test_GettersForBidOrder::13");
        assertEq(amountY, 0, "test_GettersForBidOrder::14");
        assertEq(feeX, 0, "test_GettersForBidOrder::15");
        assertEq(feeY, 0, "test_GettersForBidOrder::16");
    }

    function test_GettersForAskOrder() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId = activeId + 1;

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this));

        assertEq(order.positionId, 1, "test_GettersForAskOrder::1");

        uint256 lbLiquidity = linkWavax.balanceOf(address(limitOrderManager), askId);

        assertGt(lbLiquidity, 0, "test_GettersForAskOrder::2");
        assertEq(order.liquidity, lbLiquidity, "test_GettersForAskOrder::3");

        uint256 positionOrderId =
            limitOrderManager.getLastPositionId(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(positionOrderId, 1, "test_GettersForAskOrder::4");

        ILimitOrderManager.Position memory position = limitOrderManager.getPosition(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, positionOrderId
        );

        assertEq(position.liquidity, lbLiquidity, "test_GettersForAskOrder::5");
        assertEq(position.amount, 0, "test_GettersForAskOrder::6");
        assertEq(position.withdrawn, false, "test_GettersForAskOrder::7");

        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId),
            "test_GettersForAskOrder::8"
        );

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        assertApproxEqAbs(amountX, 1e18, 1, "test_GettersForAskOrder::9");
        assertEq(amountY, 0, "test_GettersForAskOrder::10");
        assertGt(feeX, 0, "test_GettersForAskOrder::11");
        assertEq(feeY, 0, "test_GettersForAskOrder::12");

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, 1, address(this)
        );

        assertEq(amountX, 0, "test_GettersForAskOrder::13");
        assertEq(amountY, 0, "test_GettersForAskOrder::14");
        assertEq(feeX, 0, "test_GettersForAskOrder::15");
        assertEq(feeY, 0, "test_GettersForAskOrder::16");
    }

    function test_revert_Getters() external {
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.getOrder(link, link, binStepLW, ILimitOrderManager.OrderType.BID, 1, address(this));

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.getOrder(link, wnative, 1000, ILimitOrderManager.OrderType.BID, 1, address(this));

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidTokenOrder.selector);
        limitOrderManager.getOrder(wnative, link, binStepLW, ILimitOrderManager.OrderType.BID, 1, address(this));
    }

    function test_PlaceMultipleOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        deal(address(wnative), address(this), 3e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0, 1e18);

        uint256 lbLiquidity0BeforeSecond = linkWavax.balanceOf(address(limitOrderManager), bidId0);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0, 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId1, 1e18);

        uint256 lbLiquidity1 = linkWavax.balanceOf(address(limitOrderManager), bidId1);

        ILimitOrderManager.Order memory order0 = limitOrderManager.getOrder(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0, address(this)
        );

        ILimitOrderManager.Order memory order1 = limitOrderManager.getOrder(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId1, address(this)
        );

        assertEq(order0.positionId, 1, "test_PlaceMultipleOrderForBidOrder::1");
        assertEq(order1.positionId, 1, "test_PlaceMultipleOrderForBidOrder::2");

        uint256 positionOrderId0 =
            limitOrderManager.getLastPositionId(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0);
        uint256 positionOrderId1 =
            limitOrderManager.getLastPositionId(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId1);

        assertEq(positionOrderId0, 1, "test_PlaceMultipleOrderForBidOrder::3");
        assertEq(positionOrderId1, 1, "test_PlaceMultipleOrderForBidOrder::4");

        ILimitOrderManager.Position memory position0 = limitOrderManager.getPosition(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0, positionOrderId0
        );
        ILimitOrderManager.Position memory position1 = limitOrderManager.getPosition(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId1, positionOrderId1
        );

        assertEq(position0.liquidity, lbLiquidity0BeforeSecond * 2, "test_PlaceMultipleOrderForBidOrder::5");
        assertEq(position1.liquidity, lbLiquidity1, "test_PlaceMultipleOrderForBidOrder::6");

        assertEq(position0.amount, 0, "test_PlaceMultipleOrderForBidOrder::7");
        assertEq(position1.amount, 0, "test_PlaceMultipleOrderForBidOrder::8");
    }

    function test_PlaceMultipleOrderForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId0 = activeId + 1;
        uint24 askId1 = activeId + 2;

        deal(address(link), address(this), 3e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0, 1e18);

        uint256 lbLiquidity0BeforeSecond = linkWavax.balanceOf(address(limitOrderManager), askId0);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0, 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId1, 1e18);

        uint256 lbLiquidity1 = linkWavax.balanceOf(address(limitOrderManager), askId1);

        ILimitOrderManager.Order memory order0 = limitOrderManager.getOrder(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0, address(this)
        );

        ILimitOrderManager.Order memory order1 = limitOrderManager.getOrder(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId1, address(this)
        );

        assertEq(order0.positionId, 1, "test_PlaceMultipleOrderForAskOrder::1");
        assertEq(order1.positionId, 1, "test_PlaceMultipleOrderForAskOrder::2");

        uint256 positionOrderId0 =
            limitOrderManager.getLastPositionId(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0);
        uint256 positionOrderId1 =
            limitOrderManager.getLastPositionId(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId1);

        assertEq(positionOrderId0, 1, "test_PlaceMultipleOrderForAskOrder::3");
        assertEq(positionOrderId1, 1, "test_PlaceMultipleOrderForAskOrder::4");

        ILimitOrderManager.Position memory position0 = limitOrderManager.getPosition(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0, positionOrderId0
        );
        ILimitOrderManager.Position memory position1 = limitOrderManager.getPosition(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId1, positionOrderId1
        );

        assertEq(position0.liquidity, lbLiquidity0BeforeSecond * 2, "test_PlaceMultipleOrderForAskOrder::5");
        assertEq(position1.liquidity, lbLiquidity1, "test_PlaceMultipleOrderForAskOrder::6");

        assertEq(position0.amount, 0, "test_PlaceMultipleOrderForAskOrder::7");
        assertEq(position1.amount, 0, "test_PlaceMultipleOrderForAskOrder::8");
    }

    function test_revert_PlaceOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        // trying to place an order on the active bin
        (bool success,) =
            limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId, 1e18);
        assertFalse(success, "test_revert_PlaceOrderForBidOrder::1");

        // trying to place an order on the active bin + 1 (wrong side)
        (success,) =
            limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId + 1, 1e18);
        assertFalse(success, "test_revert_PlaceOrderForBidOrder::1");

        // trying to deposit 0
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAmount.selector);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1, 0);
    }

    function test_revert_PlaceOrderForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        // trying to place an order on the active bin
        (bool success,) =
            limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId, 1e18);
        assertFalse(success, "test_revert_PlaceOrderForAskOrder::1");

        // trying to place an order on the active bin - 1 (wrong side)
        (success,) =
            limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId - 1, 1e18);
        assertFalse(success, "test_revert_PlaceOrderForAskOrder::2");

        // trying to deposit 0
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAmount.selector);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1, 0);
    }

    function test_CancelOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        uint256 lbLiquidity = linkWavax.balanceOf(address(limitOrderManager), bidId);
        (uint256 binReserveX, uint256 binReserveY) = linkWavax.getBin(bidId);
        uint256 totalSupply = linkWavax.totalSupply(bidId);

        (uint256 amountX, uint256 amountY,,) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(linkWavax.balanceOf(address(limitOrderManager), bidId), 0, "test_CancelOrderForBidOrder::1");

        assertEq(amountX, 0, "test_CancelOrderForBidOrder::2");
        assertApproxEqAbs(amountY, 1e18, 1, "test_CancelOrderForBidOrder::3");

        assertEq(link.balanceOf(address(this)), amountX, "test_CancelOrderForBidOrder::4");
        assertEq(wnative.balanceOf(address(this)), amountY, "test_CancelOrderForBidOrder::5");

        assertEq(lbLiquidity * binReserveX / totalSupply, amountX, "test_CancelOrderForBidOrder::6");
        assertEq(lbLiquidity * binReserveY / totalSupply, amountY, "test_CancelOrderForBidOrder::7");
    }

    function test_CancelOrderForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId = activeId + 1;

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        uint256 lbLiquidity = linkWavax.balanceOf(address(limitOrderManager), askId);
        (uint256 binReserveX, uint256 binReserveY) = linkWavax.getBin(askId);
        uint256 totalSupply = linkWavax.totalSupply(askId);

        (uint256 amountX, uint256 amountY,,) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(linkWavax.balanceOf(address(limitOrderManager), askId), 0, "test_CancelOrderForAskOrder::1");

        assertApproxEqAbs(amountX, 1e18, 1, "test_CancelOrderForAskOrder::2");
        assertEq(amountY, 0, "test_CancelOrderForAskOrder::3");

        assertEq(link.balanceOf(address(this)), amountX, "test_CancelOrderForAskOrder::4");
        assertEq(wnative.balanceOf(address(this)), amountY, "test_CancelOrderForAskOrder::5");

        assertEq(lbLiquidity * binReserveX / totalSupply, amountX, "test_CancelOrderForAskOrder::6");
        assertEq(lbLiquidity * binReserveY / totalSupply, amountY, "test_CancelOrderForAskOrder::7");
    }

    function test_revert_CancelOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        // trying to cancel an order that doesn't exist
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId);

        deal(address(wnative), address(this), 3e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1, 1e18);

        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1);

        // trying to cancel an order that was already cancelled
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1);

        limitOrderManager.placeOrder(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.ASK, activeId + 1, 1e18);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAddress.selector);
        limitOrderManager.cancelOrder(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.ASK, activeId + 1
        );

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1, 1e18);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAddress.selector);
        limitOrderManager.cancelOrder(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1
        );

        swapNbBins(linkWavax, true, 2);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1);

        // trying to cancel an order that was already executed
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderAlreadyExecuted.selector);
        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId - 1);
    }

    function test_revert_CancelOrderForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        // trying to cancel an order that doesn't exist
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId);

        deal(address(link), address(this), 2e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1, 1e18);

        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1);

        // trying to cancel an order that was already cancelled
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotPlaced.selector);
        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1, 1e18);

        swapNbBins(linkWavax, false, 2);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1);

        // trying to cancel an order that was already executed
        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderAlreadyExecuted.selector);
        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId + 1);
    }

    function test_ExecuteOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        uint256 price = linkWavax.getPriceFromId(bidId);

        assertEq(amountX, 0, "test_ExecuteOrderForBidOrder::1");
        assertApproxEqAbs(amountY, 1e18, 1, "test_ExecuteOrderForBidOrder::2");
        assertEq(feeX, 0, "test_ExecuteOrderForBidOrder::3");
        assertGt(feeY, 0, "test_ExecuteOrderForBidOrder::4");

        swapNbBins(linkWavax, true, 2);

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        {
            uint256 fullySwapped = (1e18 << 128) / price;

            assertApproxEqRel(amountX, fullySwapped, 1e15, "test_ExecuteOrderForBidOrder::5");
            assertEq(amountY, 0, "test_ExecuteOrderForBidOrder::6");
            assertGt(feeX, 0, "test_ExecuteOrderForBidOrder::7");
            assertEq(feeY, 0, "test_ExecuteOrderForBidOrder::8");

            // amount is greater cause the fees are compounded
            assertGt(amountX, fullySwapped, "test_ExecuteOrderForBidOrder::9");
        }

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        (uint256 executedAmountX, uint256 executedAmountY, uint256 executionFeeX, uint256 executionFeeY) =
        limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        assertEq(executedAmountX, amountX - feeX, "test_ExecuteOrderForBidOrder::10");
        assertEq(executedAmountY, amountY - feeY, "test_ExecuteOrderForBidOrder::11");
        assertEq(executionFeeX, 0, "test_ExecuteOrderForBidOrder::12");
        assertEq(executionFeeY, 0, "test_ExecuteOrderForBidOrder::13");
    }

    function test_ExecuteOrderForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId = activeId + 1;

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        uint256 price = linkWavax.getPriceFromId(askId);

        assertApproxEqAbs(amountX, 1e18, 1, "test_ExecuteOrderForAskOrder::1");
        assertEq(amountY, 0, "test_ExecuteOrderForAskOrder::2");
        assertGt(feeX, 0, "test_ExecuteOrderForAskOrder::3");
        assertEq(feeY, 0, "test_ExecuteOrderForAskOrder::4");

        swapNbBins(linkWavax, false, 2);

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        {
            uint256 fullySwapped = (price * 1e18) >> 128;

            assertEq(amountX, 0, "test_ExecuteOrderForAskOrder::5");
            assertApproxEqRel(amountY, fullySwapped, 1e15, "test_ExecuteOrderForAskOrder::6");
            assertEq(feeX, 0, "test_ExecuteOrderForAskOrder::7");
            assertGt(feeY, 0, "test_ExecuteOrderForAskOrder::8");

            // amount is greater cause the fees are compounded
            assertGt(amountY, fullySwapped, "test_ExecuteOrderForAskOrder::9");
        }

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        (uint256 executedAmountX, uint256 executedAmountY, uint256 executionFeeX, uint256 executionFeeY) =
        limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        assertEq(executedAmountX, amountX - feeX, "test_ExecuteOrderForAskOrder::10");
        assertEq(executedAmountY, amountY - feeY, "test_ExecuteOrderForAskOrder::11");
        assertEq(executionFeeX, 0, "test_ExecuteOrderForAskOrder::12");
        assertEq(executionFeeY, 0, "test_ExecuteOrderForAskOrder::13");
    }

    function test_revert_ExecuteOrders() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;
        uint24 askId = activeId + 1;

        (bool success,) =
            limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);
        assertFalse(success, "test_revert_ExecuteOrders::1");

        (success,) =
            limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, activeId);
        assertFalse(success, "test_revert_ExecuteOrders::2");

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);
        assertFalse(success, "test_revert_ExecuteOrders::3");

        (success,) =
            limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, activeId);
        assertFalse(success, "test_revert_ExecuteOrders::4");

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, askId);
        assertFalse(success, "test_revert_ExecuteOrders::5");

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, bidId);
        assertFalse(success, "test_revert_ExecuteOrders::6");

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        swapNbBins(linkWavax, true, 2);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__ZeroAddress.selector);
        limitOrderManager.executeOrders(link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);
        assertFalse(success, "test_revert_ExecuteOrders::7");

        swapNbBins(linkWavax, false, 4);
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);
        assertFalse(success, "test_revert_ExecuteOrders::8");

        swapNbBins(linkWavax, true, 2);

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        limitOrderManager.cancelOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        swapNbBins(linkWavax, true, 2);

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);
        assertFalse(success, "test_revert_ExecuteOrders::9");

        swapNbBins(linkWavax, false, 4);

        (success,) = limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);
        assertFalse(success, "test_revert_ExecuteOrders::10");
    }

    function test_ClaimOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        vm.startPrank(alice);
        deal(address(wnative), alice, 1e18);
        wnative.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);
        vm.stopPrank();

        swapNbBins(linkWavax, true, 2);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice
        );

        vm.prank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        assertEq(link.balanceOf(alice), amountX - feeX, "test_ClaimOrderForBidOrder::1");
        assertEq(wnative.balanceOf(alice), amountY - feeY, "test_ClaimOrderForBidOrder::2");
        assertEq(feeX, 0, "test_ClaimOrderForBidOrder::3");
        assertEq(feeY, 0, "test_ClaimOrderForBidOrder::4");

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice
        );

        assertEq(amountX, 0, "test_ClaimOrderForBidOrder::5");
        assertEq(amountY, 0, "test_ClaimOrderForBidOrder::6");
        assertEq(feeX, 0, "test_ClaimOrderForBidOrder::7");
        assertEq(feeY, 0, "test_ClaimOrderForBidOrder::8");

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(order.positionId, 0, "test_ClaimOrderForBidOrder::9");
        assertEq(order.liquidity, 0, "test_ClaimOrderForBidOrder::10");
    }

    function test_ClaimOrderForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId = activeId + 1;

        vm.startPrank(alice);
        deal(address(link), alice, 1e18);
        link.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);
        vm.stopPrank();

        swapNbBins(linkWavax, false, 2);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice
        );

        vm.prank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(link.balanceOf(alice), amountX, "test_ClaimOrderForAskOrder::1");
        assertEq(wnative.balanceOf(alice), amountY, "test_ClaimOrderForAskOrder::2");
        assertEq(feeX, 0, "test_ClaimOrderForAskOrder::3");
        assertEq(feeY, 0, "test_ClaimOrderForAskOrder::4");

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice
        );

        assertEq(amountX, 0, "test_ClaimOrderForAskOrder::5");
        assertEq(amountY, 0, "test_ClaimOrderForAskOrder::6");
        assertEq(feeX, 0, "test_ClaimOrderForAskOrder::7");
        assertEq(feeY, 0, "test_ClaimOrderForAskOrder::8");

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(order.positionId, 0, "test_ClaimOrderForAskOrder::9");
        assertEq(order.liquidity, 0, "test_ClaimOrderForAskOrder::10");
    }

    function test_revert_ClaimOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;
        uint24 askId = activeId + 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotClaimable.selector);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotClaimable.selector);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__OrderNotExecutable.selector);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);
    }

    function test_ExecuteOnClaimForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        vm.startPrank(alice);
        deal(address(wnative), alice, 1e18);
        wnative.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);
        vm.stopPrank();

        uint256 liquidity = linkWavax.balanceOf(address(limitOrderManager), bidId);

        swapNbBins(linkWavax, true, 2);

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice
        );

        vm.prank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        // Alice receives the fees as well as she executed the order
        assertEq(link.balanceOf(alice), amountX, "test_ExecuteOnClaimForBidOrder::1");
        assertEq(wnative.balanceOf(alice), amountY - feeY, "test_ExecuteOnClaimForBidOrder::2");
        assertGt(feeX, 0, "test_ExecuteOnClaimForBidOrder::3");
        assertEq(feeY, 0, "test_ExecuteOnClaimForBidOrder::4");

        {
            (uint256 amountXAfter, uint256 amountYAfter, uint256 feeXAfter, uint256 feeYAfter) = limitOrderManager
                .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice);

            assertEq(amountXAfter, 0, "test_ExecuteOnClaimForBidOrder::5");
            assertEq(amountYAfter, 0, "test_ExecuteOnClaimForBidOrder::6");
            assertEq(feeXAfter, 0, "test_ExecuteOnClaimForBidOrder::7");
            assertEq(feeYAfter, 0, "test_ExecuteOnClaimForBidOrder::8");
        }

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(order.positionId, 0, "test_ExecuteOnClaimForBidOrder::9");
        assertEq(order.liquidity, 0, "test_ExecuteOnClaimForBidOrder::10");

        ILimitOrderManager.Position memory position =
            limitOrderManager.getPosition(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1);

        assertEq(position.liquidity, liquidity, "test_ExecuteOnClaimForBidOrder::11");
        assertEq(position.amount, amountX - feeX, "test_ExecuteOnClaimForBidOrder::12");
        assertEq(position.withdrawn, true, "test_ExecuteOnClaimForBidOrder::13");

        (bool success,) =
            limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);
        assertFalse(success, "test_ExecuteOnClaimForBidOrder::14");
    }

    function test_ExecuteOnClaimForAskOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId = activeId + 1;

        vm.startPrank(alice);
        deal(address(link), alice, 1e18);
        link.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);
        vm.stopPrank();

        uint256 liquidity = linkWavax.balanceOf(address(limitOrderManager), askId);

        swapNbBins(linkWavax, false, 2);

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice
        );

        vm.prank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(link.balanceOf(alice), amountX - feeX, "test_ExecuteOnClaimForAskOrder::1");
        // Alice receives the fees as well as she executed the order
        assertEq(wnative.balanceOf(alice), amountY, "test_ExecuteOnClaimForAskOrder::2");
        assertEq(feeX, 0, "test_ExecuteOnClaimForAskOrder::3");
        assertGt(feeY, 0, "test_ExecuteOnClaimForAskOrder::4");

        {
            (uint256 amountXAfter, uint256 amountYAfter, uint256 feeXAfter, uint256 feeYAfter) = limitOrderManager
                .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice);

            assertEq(amountXAfter, 0, "test_ExecuteOnClaimForAskOrder::5");
            assertEq(amountYAfter, 0, "test_ExecuteOnClaimForAskOrder::6");
            assertEq(feeXAfter, 0, "test_ExecuteOnClaimForAskOrder::7");
            assertEq(feeYAfter, 0, "test_ExecuteOnClaimForAskOrder::8");
        }

        ILimitOrderManager.Order memory order =
            limitOrderManager.getOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(order.positionId, 0, "test_ExecuteOnClaimForAskOrder::9");
        assertEq(order.liquidity, 0, "test_ExecuteOnClaimForAskOrder::10");

        ILimitOrderManager.Position memory position =
            limitOrderManager.getPosition(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1);

        assertEq(position.liquidity, liquidity, "test_ExecuteOnClaimForAskOrder::11");
        assertEq(position.amount, amountY - feeY, "test_ExecuteOnClaimForAskOrder::12");
        assertEq(position.withdrawn, true, "test_ExecuteOnClaimForAskOrder::13");

        (bool success,) =
            limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);
        assertFalse(success, "test_ExecuteOnClaimForAskOrder::14");
    }

    struct Amounts {
        uint256 amountX;
        uint256 amountY;
        uint256 feeX;
        uint256 feeY;
    }

    function test_ClaimOnPlaceOrderForBidOrder() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        vm.startPrank(alice);
        deal(address(wnative), alice, 2e18);
        wnative.approve(address(limitOrderManager), 2e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);
        vm.stopPrank();

        Amounts memory amounts;

        (amounts.amountX, amounts.amountY, amounts.feeX, amounts.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice
        );

        swapNbBins(linkWavax, true, 2);

        Amounts memory amountsAfter;

        (amountsAfter.amountX, amountsAfter.amountY, amountsAfter.feeX, amountsAfter.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        swapNbBins(linkWavax, false, 2);

        vm.prank(alice);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18);

        Amounts memory amountsAfter2;

        (amountsAfter2.amountX, amountsAfter2.amountY, amountsAfter2.feeX, amountsAfter2.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, alice);

        assertEq(amountsAfter2.amountX, amounts.amountX, "test_ClaimOnPlaceOrderForBidOrder::1");
        assertEq(amountsAfter2.amountY, amounts.amountY, "test_ClaimOnPlaceOrderForBidOrder::2");
        assertEq(amountsAfter2.feeX, amounts.feeX, "test_ClaimOnPlaceOrderForBidOrder::3");
        assertEq(amountsAfter2.feeY, amounts.feeY, "test_ClaimOnPlaceOrderForBidOrder::4");

        assertEq(
            link.balanceOf(alice), amountsAfter.amountX - amountsAfter.feeX, "test_ClaimOnPlaceOrderForBidOrder::5"
        );
        assertEq(
            wnative.balanceOf(alice), amountsAfter.amountY - amountsAfter.feeY, "test_ClaimOnPlaceOrderForBidOrder::6"
        );

        swapNbBins(linkWavax, true, 2);

        vm.prank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId);

        // Alice receives the 2nd fees as well as she executed the 2nd order
        assertEq(
            link.balanceOf(alice), 2 * amountsAfter.amountX - amountsAfter.feeX, "test_ClaimOnPlaceOrderForBidOrder::7"
        );
        assertEq(wnative.balanceOf(alice), 0, "test_ClaimOnPlaceOrderForBidOrder::8");
    }

    function test_ClaimOnPlaceOrderForAskOrder() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId = activeId + 1;

        vm.startPrank(alice);
        deal(address(link), alice, 2e18);
        link.approve(address(limitOrderManager), 2e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);
        vm.stopPrank();

        Amounts memory amounts;

        (amounts.amountX, amounts.amountY, amounts.feeX, amounts.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice
        );

        swapNbBins(linkWavax, false, 2);

        Amounts memory amountsAfter;

        (amountsAfter.amountX, amountsAfter.amountY, amountsAfter.feeX, amountsAfter.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        swapNbBins(linkWavax, true, 2);

        vm.prank(alice);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18);

        Amounts memory amountsAfter2;

        (amountsAfter2.amountX, amountsAfter2.amountY, amountsAfter2.feeX, amountsAfter2.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, alice);

        assertEq(amountsAfter2.amountX, amounts.amountX, "test_ClaimOnPlaceOrderForAskOrder::1");
        assertEq(amountsAfter2.amountY, amounts.amountY, "test_ClaimOnPlaceOrderForAskOrder::2");
        assertEq(amountsAfter2.feeX, amounts.feeX, "test_ClaimOnPlaceOrderForAskOrder::3");
        assertEq(amountsAfter2.feeY, amounts.feeY, "test_ClaimOnPlaceOrderForAskOrder::4");

        assertEq(
            link.balanceOf(alice), amountsAfter.amountX - amountsAfter.feeX, "test_ClaimOnPlaceOrderForAskOrder::5"
        );
        assertEq(
            wnative.balanceOf(alice), amountsAfter.amountY - amountsAfter.feeY, "test_ClaimOnPlaceOrderForAskOrder::6"
        );

        swapNbBins(linkWavax, false, 2);

        vm.prank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId);

        assertEq(link.balanceOf(alice), 0, "test_ClaimOnPlaceOrderForAskOrder::7");
        // Alice receives the 2nd fees as well as she executed the 2nd order
        assertEq(
            wnative.balanceOf(alice),
            2 * amountsAfter.amountY - amountsAfter.feeY,
            "test_ClaimOnPlaceOrderForAskOrder::8"
        );
    }

    function test_BatchOrdersForBidOrders() external {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;
        uint24 bidId2 = activeId - 3;
        uint24 bidId3 = activeId - 4;

        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](4);

        params[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId2,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId3,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(wnative), alice, 4e18);
        wnative.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrders(params);
        vm.stopPrank();

        swapNbBins(linkWavax, true, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0),
            "test_BatchOrdersForBidOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId1),
            "test_BatchOrdersForBidOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId2),
            "test_BatchOrdersForBidOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId3),
            "test_BatchOrdersForBidOrders::4"
        );

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](2);

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1
        });

        vm.prank(address(1));
        limitOrderManager.batchExecuteOrders(orderParams);

        // Reset alice's balance
        deal(address(link), alice, 0);
        deal(address(wnative), alice, 0);

        Amounts memory amounts2;

        (amounts2.amountX, amounts2.amountY, amounts2.feeX, amounts2.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId2, alice
        );

        assertGt(amounts2.amountX, 0, "test_BatchOrdersForBidOrders::5");
        assertGt(amounts2.amountY, 0, "test_BatchOrdersForBidOrders::6");
        assertGt(amounts2.feeX, 0, "test_BatchOrdersForBidOrders::7");
        assertGt(amounts2.feeY, 0, "test_BatchOrdersForBidOrders::8");

        Amounts memory amounts3;

        (amounts3.amountX, amounts3.amountY, amounts3.feeX, amounts3.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId3, alice
        );

        assertEq(amounts3.amountX, 0, "test_BatchOrdersForBidOrders::9");
        assertGt(amounts3.amountY, 0, "test_BatchOrdersForBidOrders::10");
        assertEq(amounts3.feeX, 0, "test_BatchOrdersForBidOrders::11");
        assertGt(amounts3.feeY, 0, "test_BatchOrdersForBidOrders::12");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId2
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId3
        });

        vm.prank(alice);
        limitOrderManager.batchCancelOrders(orderParams);

        assertEq(link.balanceOf(alice), amounts2.amountX + amounts3.amountX, "test_BatchOrdersForBidOrders::13");
        assertEq(wnative.balanceOf(alice), amounts2.amountY + amounts3.amountY, "test_BatchOrdersForBidOrders::14");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1
        });

        vm.prank(alice);
        limitOrderManager.batchClaimOrders(orderParams);

        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            link.balanceOf(alice),
            4 * (amounts2.amountX - amounts2.feeX) + (amounts2.amountX - amounts2.feeX)
                + (amounts3.amountX - amounts3.feeX),
            1e16,
            "test_BatchOrdersForBidOrders::15"
        );
        assertEq(wnative.balanceOf(alice), amounts2.amountY + amounts3.amountY, "test_BatchOrdersForBidOrders::16");
    }

    function test_BatchOrdersForAskOrders() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 askId0 = activeId + 1;
        uint24 askId1 = activeId + 2;
        uint24 askId2 = activeId + 3;
        uint24 askId3 = activeId + 4;

        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](4);

        params[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId2,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId3,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(link), alice, 4e18);
        link.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrders(params);
        vm.stopPrank();

        swapNbBins(linkWavax, false, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0),
            "test_BatchOrdersForAskOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId1),
            "test_BatchOrdersForAskOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId2),
            "test_BatchOrdersForAskOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId3),
            "test_BatchOrdersForAskOrders::4"
        );

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](2);

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1
        });

        vm.prank(address(1));
        limitOrderManager.batchExecuteOrders(orderParams);

        // Reset alice's balance
        deal(address(link), alice, 0);
        deal(address(wnative), alice, 0);

        Amounts memory amounts2;

        (amounts2.amountX, amounts2.amountY, amounts2.feeX, amounts2.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId2, alice
        );

        assertGt(amounts2.amountX, 0, "test_BatchOrdersForAskOrders::5");
        assertGt(amounts2.amountY, 0, "test_BatchOrdersForAskOrders::6");
        assertGt(amounts2.feeX, 0, "test_BatchOrdersForAskOrders::7");
        assertGt(amounts2.feeY, 0, "test_BatchOrdersForAskOrders::8");

        Amounts memory amounts3;

        (amounts3.amountX, amounts3.amountY, amounts3.feeX, amounts3.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId3, alice
        );

        assertGt(amounts3.amountX, 0, "test_BatchOrdersForAskOrders::9");
        assertEq(amounts3.amountY, 0, "test_BatchOrdersForAskOrders::10");
        assertGt(amounts3.feeX, 0, "test_BatchOrdersForAskOrders::11");
        assertEq(amounts3.feeY, 0, "test_BatchOrdersForAskOrders::12");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId2
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId3
        });

        vm.prank(alice);
        limitOrderManager.batchCancelOrders(orderParams);

        assertEq(link.balanceOf(alice), amounts2.amountX + amounts3.amountX, "test_BatchOrdersForAskOrders::13");
        assertEq(wnative.balanceOf(alice), amounts2.amountY + amounts3.amountY, "test_BatchOrdersForAskOrders::14");

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId1
        });

        vm.prank(alice);
        limitOrderManager.batchClaimOrders(orderParams);

        assertEq(link.balanceOf(alice), amounts2.amountX + amounts3.amountX, "test_BatchOrdersForAskOrders::15");
        // The successful positions are almost of `2 * amountY2` as order2 was half filled
        assertApproxEqRel(
            wnative.balanceOf(alice),
            4 * (amounts2.amountY - amounts2.feeY) + (amounts2.amountY - amounts2.feeY)
                + (amounts3.amountY - amounts3.feeY),
            1e16,
            "test_BatchOrdersForBidOrders::15"
        );
    }

    function test_revert_BatchOrders() public {
        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](0);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchPlaceOrders(params);

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](0);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        vm.prank(address(1));
        limitOrderManager.batchExecuteOrders(orderParams);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchCancelOrders(orderParams);

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidBatchLength.selector);
        limitOrderManager.batchClaimOrders(orderParams);
    }

    function test_BatchOrdersSamePairForBidOrders() public {
        uint24 activeId = linkWavax.getActiveId();

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
        deal(address(wnative), alice, 4e18);
        wnative.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrdersSamePair(link, wnative, binStepLW, params);
        vm.stopPrank();

        swapNbBins(linkWavax, true, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId0),
            "test_BatchOrdersForBidOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId1),
            "test_BatchOrdersForBidOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId2),
            "test_BatchOrdersForBidOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId3),
            "test_BatchOrdersForBidOrders::4"
        );

        ILimitOrderManager.OrderParamsSamePair[] memory orderParams = new ILimitOrderManager.OrderParamsSamePair[](2);

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId1});

        vm.prank(address(1));
        limitOrderManager.batchExecuteOrdersSamePair(link, wnative, binStepLW, orderParams);

        // Reset alice's balance
        deal(address(link), alice, 0);
        deal(address(wnative), alice, 0);

        Amounts memory amounts2;

        (amounts2.amountX, amounts2.amountY, amounts2.feeX, amounts2.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId2, alice
        );

        assertGt(amounts2.amountX, 0, "test_BatchOrdersForBidOrders::5");
        assertGt(amounts2.amountY, 0, "test_BatchOrdersForBidOrders::6");
        assertGt(amounts2.feeY, 0, "test_BatchOrdersForBidOrders::7");
        assertGt(amounts2.feeX, 0, "test_BatchOrdersForBidOrders::7");

        Amounts memory amounts3;

        (amounts3.amountX, amounts3.amountY, amounts3.feeX, amounts3.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId3, alice
        );

        assertEq(amounts3.amountX, 0, "test_BatchOrdersForBidOrders::8");
        assertGt(amounts3.amountY, 0, "test_BatchOrdersForBidOrders::9");
        assertEq(amounts3.feeX, 0, "test_BatchOrdersForBidOrders::10");
        assertGt(amounts3.feeY, 0, "test_BatchOrdersForBidOrders::11");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId2});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId3});

        vm.prank(alice);
        limitOrderManager.batchCancelOrdersSamePair(link, wnative, binStepLW, orderParams);

        assertEq(link.balanceOf(alice), amounts2.amountX + amounts3.amountX, "test_BatchOrdersForBidOrders::12");
        assertEq(wnative.balanceOf(alice), amounts2.amountY + amounts3.amountY, "test_BatchOrdersForBidOrders::13");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.BID, binId: bidId1});

        vm.prank(alice);
        limitOrderManager.batchClaimOrdersSamePair(link, wnative, binStepLW, orderParams);

        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            link.balanceOf(alice),
            4 * (amounts2.amountX - amounts2.feeX) + (amounts2.amountX - amounts2.feeX)
                + (amounts3.amountX - amounts3.feeX),
            1e16,
            "test_BatchOrdersForBidOrders::11"
        );
        assertEq(wnative.balanceOf(alice), amounts2.amountY + amounts3.amountY, "test_BatchOrdersForBidOrders::12");
    }

    function test_BatchOrdersSamePairForAskOrders() public {
        uint24 activeId = linkWavax.getActiveId();

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
        deal(address(link), alice, 4e18);
        link.approve(address(limitOrderManager), 4e18);

        limitOrderManager.batchPlaceOrdersSamePair(link, wnative, binStepLW, params);
        vm.stopPrank();

        swapNbBins(linkWavax, false, 3);

        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId0),
            "test_BatchOrdersForAskOrders::1"
        );
        assertTrue(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId1),
            "test_BatchOrdersForAskOrders::2"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId2),
            "test_BatchOrdersForAskOrders::3"
        );
        assertFalse(
            limitOrderManager.isOrderExecutable(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId3),
            "test_BatchOrdersForAskOrders::4"
        );

        ILimitOrderManager.OrderParamsSamePair[] memory orderParams = new ILimitOrderManager.OrderParamsSamePair[](2);

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId1});

        vm.prank(address(1));
        limitOrderManager.batchExecuteOrdersSamePair(link, wnative, binStepLW, orderParams);

        // Reset alice's balance
        deal(address(link), alice, 0);
        deal(address(wnative), alice, 0);

        Amounts memory amounts2;

        (amounts2.amountX, amounts2.amountY, amounts2.feeX, amounts2.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId2, alice
        );

        assertGt(amounts2.amountX, 0, "test_BatchOrdersForAskOrders::5");
        assertGt(amounts2.amountY, 0, "test_BatchOrdersForAskOrders::6");
        assertGt(amounts2.feeX, 0, "test_BatchOrdersForAskOrders::7");
        assertGt(amounts2.feeY, 0, "test_BatchOrdersForAskOrders::8");

        Amounts memory amounts3;

        (amounts3.amountX, amounts3.amountY, amounts3.feeX, amounts3.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId3, alice
        );

        assertGt(amounts3.amountX, 0, "test_BatchOrdersForAskOrders::9");
        assertEq(amounts3.amountY, 0, "test_BatchOrdersForAskOrders::10");
        assertGt(amounts3.feeX, 0, "test_BatchOrdersForAskOrders::11");
        assertEq(amounts3.feeY, 0, "test_BatchOrdersForAskOrders::12");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId2});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId3});

        vm.prank(alice);
        limitOrderManager.batchCancelOrdersSamePair(link, wnative, binStepLW, orderParams);

        assertEq(link.balanceOf(alice), amounts2.amountX + amounts3.amountX, "test_BatchOrdersForAskOrders::13");
        assertEq(wnative.balanceOf(alice), amounts2.amountY + amounts3.amountY, "test_BatchOrdersForAskOrders::14");

        orderParams[0] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId0});

        orderParams[1] =
            ILimitOrderManager.OrderParamsSamePair({orderType: ILimitOrderManager.OrderType.ASK, binId: askId1});

        vm.prank(alice);
        limitOrderManager.batchClaimOrdersSamePair(link, wnative, binStepLW, orderParams);

        assertEq(link.balanceOf(alice), amounts2.amountX + amounts3.amountX, "test_BatchOrdersForAskOrders::15");
        // The successful positions are almost of `2 * amountX2` as order2 was half filled
        assertApproxEqRel(
            wnative.balanceOf(alice),
            4 * (amounts2.amountY - amounts2.feeY) + (amounts2.amountY - amounts2.feeY)
                + (amounts3.amountY - amounts3.feeY),
            1e16,
            "test_BatchOrdersForAskOrders::12"
        );
    }

    function test_PlaceOrderNative() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;

        assertEq(address(wnative), address(wnative), "test_PlaceOrderNative::1");

        limitOrderManager.placeOrder{value: 1e18}(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.ASK, wavaxusdc.getActiveId() + 1, 1e18
        );

        uint256 balanceBefore = address(this).balance;

        limitOrderManager.placeOrder{value: 1e18 + 1}(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        assertEq(address(this).balance, balanceBefore - 1e18, "test_PlaceOrderNative::2");

        balanceBefore = address(this).balance;

        limitOrderManager.placeOrder{value: 1e18 + 1}(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.ASK, wavaxusdc.getActiveId() + 1, 1e18
        );

        assertEq(address(this).balance, balanceBefore - 1e18, "test_PlaceOrderNative::3");
    }

    function test_PlaceOrderNative_revert() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId = activeId - 1;
        uint24 askId = activeId + 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18 - 1}(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        uint24 avaxUsdcBidId = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair.getActiveId() - 1;

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, avaxUsdcBidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            wnative, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            wnative, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.BID, bidId, 1e18
        );

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidPair.selector);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, askId, 1e18
        );
    }

    function test_BatchPlaceOrdersNative() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        assertEq(address(wnative), address(wnative), "test_BatchPlaceOrdersNative::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

        uint24 askId0 = wavaxusdc.getActiveId() + 1;
        uint24 askId1 = wavaxusdc.getActiveId() + 2;

        ILimitOrderManager.PlaceOrderParams[] memory orderParams = new ILimitOrderManager.PlaceOrderParams[](2);

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
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
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
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
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrders{value: 2e18}(orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrders{value: 2e18 + 1}(orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersNative::4");

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        limitOrderManager.batchPlaceOrders{value: 2e18}(orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrders{value: 2e18 + 1}(orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersNative::4");

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId1,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        deal(address(wnative), address(this), 1e18);
        limitOrderManager.batchPlaceOrders{value: 1e18}(orderParams);
    }

    function test_BatchPlaceOrders_revert() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId0 = activeId - 1;

        assertEq(address(wnative), address(wnative), "test_BatchPlaceOrdersNative::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

        uint24 askId0 = wavaxusdc.getActiveId() + 1;

        ILimitOrderManager.PlaceOrderParams[] memory orderParams = new ILimitOrderManager.PlaceOrderParams[](2);

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        vm.expectRevert(ILimitOrderManager.LimitOrderManager__InvalidNativeAmount.selector);
        limitOrderManager.batchPlaceOrders{value: 2e18 - 1}(orderParams);

        orderParams[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId0,
            amount: 1e18
        });

        orderParams[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId0,
            amount: 1e18
        });

        deal(address(wnative), address(this), 1e18);
    }

    function test_BatchPlaceOrdersSamePairNative() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        assertEq(address(wnative), address(wnative), "test_BatchPlaceOrdersSamePairNative::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

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

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18}(link, IERC20(address(0)), binStepLW, orderParams);

        uint256 balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 + 1}(link, IERC20(address(0)), binStepLW, orderParams);

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

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18}(IERC20(address(0)), usdc, binStepWU, orderParams);

        balanceBefore = address(this).balance;

        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 + 1}(IERC20(address(0)), usdc, binStepWU, orderParams);

        assertEq(address(this).balance, balanceBefore - 2e18, "test_BatchPlaceOrdersSamePairNative::3");
    }

    function test_BatchPlaceOrdersSamePair_revert() public {
        uint24 activeId = linkWavax.getActiveId();

        uint24 bidId0 = activeId - 1;
        uint24 bidId1 = activeId - 2;

        assertEq(address(wnative), address(wnative), "test_BatchPlaceOrdersSamePair_revert::1");

        ILBPair wavaxusdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

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
        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 - 1}(link, IERC20(address(0)), binStepLW, orderParams);

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
        limitOrderManager.batchPlaceOrdersSamePair{value: 2e18 - 1}(IERC20(address(0)), usdc, binStepWU, orderParams);
    }

    function test_ClaimOrderNative() public {
        ILBPair wavaxUsdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

        uint24 linkWavaxAskId = linkWavax.getActiveId() + 1;
        uint24 wavaxUsdcBidId = wavaxUsdc.getActiveId() - 1;

        deal(address(link), address(this), 1e18);
        limitOrderManager.placeOrder(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId, 1e18
        );

        swapNbBins(linkWavax, false, 2);

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId);

        uint256 balanceBefore = address(this).balance;
        uint256 wnativeBalanceBefore = wnative.balanceOf(address(this));

        Amounts memory claimable;

        (claimable.amountX, claimable.amountY, claimable.feeX, claimable.feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId, address(this)
        );

        limitOrderManager.claimOrder(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId
        );

        assertEq(claimable.amountX, 0, "test_ClaimOrderNative::1");
        assertGt(address(this).balance, balanceBefore, "test_ClaimOrderNative::2");
        assertEq(address(this).balance, balanceBefore + claimable.amountY - claimable.feeY, "test_ClaimOrderNative::3");
        assertEq(wnative.balanceOf(address(this)), wnativeBalanceBefore, "test_ClaimOrderNative::4");

        usdc.approve(address(limitOrderManager), type(uint256).max);
        deal(address(usdc), address(this), 10e6);
        limitOrderManager.placeOrder(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId, 10e6
        );

        swapNbBins(wavaxUsdc, true, 2);

        vm.prank(address(1));
        limitOrderManager.executeOrders(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId);

        balanceBefore = address(this).balance;
        wnativeBalanceBefore = wnative.balanceOf(address(this));

        (claimable.amountX, claimable.amountY, claimable.feeX, claimable.feeY) = limitOrderManager.getCurrentAmounts(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId, address(this)
        );

        limitOrderManager.claimOrder(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId
        );

        assertEq(claimable.amountY, 0, "test_ClaimOrderNative::5");
        assertGt(address(this).balance, balanceBefore, "test_ClaimOrderNative::6");
        assertEq(address(this).balance, balanceBefore + claimable.amountX - claimable.feeX, "test_ClaimOrderNative::7");
        assertEq(wnative.balanceOf(address(this)), wnativeBalanceBefore, "test_ClaimOrderNative::8");
    }

    function test_BatchClaimOrdersNative() public {
        ILBPair wavaxUsdc = lbFactory.getLBPairInformation(wnative, usdc, binStepWU).LBPair;

        uint24 linkWavaxAskId1 = linkWavax.getActiveId() + 1;
        uint24 linkWavaxAskId2 = linkWavaxAskId1 + 1;

        uint24 wavaxUsdcBidId1 = wavaxUsdc.getActiveId() - 1;
        uint24 wavaxUsdcBidId2 = wavaxUsdcBidId1 - 1;

        deal(address(link), address(this), 2e18);

        limitOrderManager.placeOrder(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId1, 1e18
        );
        limitOrderManager.placeOrder(
            link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId2, 1e18
        );

        usdc.approve(address(limitOrderManager), type(uint256).max);
        deal(address(usdc), address(this), 20e6);

        limitOrderManager.placeOrder(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId1, 10e6
        );
        limitOrderManager.placeOrder(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId2, 10e6
        );

        swapNbBins(linkWavax, false, 3);
        swapNbBins(wavaxUsdc, true, 3);

        Amounts memory lwClaimable1;
        Amounts memory lwClaimable2;
        Amounts memory wuClaimable1;
        Amounts memory wuClaimable2;

        (lwClaimable1.amountX, lwClaimable1.amountY, lwClaimable1.feeX, lwClaimable1.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId1, address(this));

        (lwClaimable2.amountX, lwClaimable2.amountY, lwClaimable2.feeX, lwClaimable2.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId2, address(this));

        (wuClaimable1.amountX, wuClaimable1.amountY, wuClaimable1.feeX, wuClaimable1.feeY) = limitOrderManager
            .getCurrentAmounts(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId1, address(this)
        );

        (wuClaimable2.amountX, wuClaimable2.amountY, wuClaimable2.feeX, wuClaimable2.feeY) = limitOrderManager
            .getCurrentAmounts(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId2, address(this)
        );

        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId1);
        vm.prank(address(1));
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, linkWavaxAskId2);
        vm.prank(address(1));
        limitOrderManager.executeOrders(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId1);
        vm.prank(address(1));
        limitOrderManager.executeOrders(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.BID, wavaxUsdcBidId2);

        uint256 balanceBefore = address(this).balance;
        uint256 wnativeBalanceBefore = wnative.balanceOf(address(this));

        ILimitOrderManager.OrderParams[] memory orderParams = new ILimitOrderManager.OrderParams[](4);

        orderParams[0] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: linkWavaxAskId1
        });

        orderParams[1] = ILimitOrderManager.OrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: linkWavaxAskId2
        });

        orderParams[2] = ILimitOrderManager.OrderParams({
            tokenX: wnative,
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: wavaxUsdcBidId1
        });

        orderParams[3] = ILimitOrderManager.OrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: wavaxUsdcBidId2
        });

        limitOrderManager.batchClaimOrders(orderParams);

        assertGt(address(this).balance, balanceBefore, "test_BatchClaimOrdersNative::1");
        assertEq(
            address(this).balance,
            balanceBefore + lwClaimable1.amountY + wuClaimable2.amountX - lwClaimable1.feeY - wuClaimable2.feeX,
            "test_BatchClaimOrdersNative::2"
        );
        assertEq(
            lwClaimable1.amountX + wuClaimable2.amountY + lwClaimable1.feeX + wuClaimable2.feeY,
            0,
            "test_BatchClaimOrdersNative::3"
        );

        assertGt(wnative.balanceOf(address(this)), wnativeBalanceBefore, "test_BatchClaimOrdersNative::4");
        assertEq(
            wnative.balanceOf(address(this)),
            wnativeBalanceBefore + lwClaimable2.amountY + wuClaimable1.amountX - lwClaimable2.feeY - wuClaimable1.feeX,
            "test_BatchClaimOrdersNative::5"
        );
        assertEq(
            lwClaimable2.amountX + wuClaimable1.amountY + lwClaimable2.feeX + wuClaimable1.feeY,
            0,
            "test_BatchClaimOrdersNative::6"
        );
    }

    function test_OrderMultipleUsers() public {
        uint24 bidIdLW = linkWavax.getActiveId() - 1;
        uint24 askIdLW = linkWavax.getActiveId() + 1;

        uint24 bidIdWU = wavaxUsdc.getActiveId() - 1;
        uint24 askIdWU = wavaxUsdc.getActiveId() + 1;

        vm.startPrank(alice);
        deal(address(wnative), alice, 1e18);
        deal(alice, 1e18);

        wnative.approve(address(limitOrderManager), 1e18);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidIdLW, 1e18);
        limitOrderManager.placeOrder{value: 1e18}(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.ASK, askIdWU, 1e18
        );
        vm.stopPrank();

        vm.startPrank(bob);
        deal(address(link), bob, 1e18);
        deal(address(usdc), bob, 10e6);

        link.approve(address(limitOrderManager), 1e18);
        usdc.approve(address(limitOrderManager), 10e6);

        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askIdLW, 1e18);
        limitOrderManager.placeOrder(
            IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, bidIdWU, 10e6
        );
        vm.stopPrank();

        Amounts memory amountsBidLW;
        Amounts memory amountsAskWU;
        Amounts memory amountsAskLW;
        Amounts memory amountsBidWU;

        swapNbBins(linkWavax, true, 2);
        swapNbBins(wavaxUsdc, false, 2);

        (amountsBidLW.amountX, amountsBidLW.amountY, amountsBidLW.feeX, amountsBidLW.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidIdLW, alice);
        (amountsAskWU.amountX, amountsAskWU.amountY, amountsAskWU.feeX, amountsAskWU.feeY) = limitOrderManager
            .getCurrentAmounts(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.ASK, askIdWU, alice);

        vm.startPrank(carol);
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidIdLW);
        limitOrderManager.executeOrders(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.ASK, askIdWU);
        vm.stopPrank();

        swapNbBins(linkWavax, false, 4);
        swapNbBins(wavaxUsdc, true, 4);

        (amountsAskLW.amountX, amountsAskLW.amountY, amountsAskLW.feeX, amountsAskLW.feeY) = limitOrderManager
            .getCurrentAmounts(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askIdLW, bob);
        (amountsBidWU.amountX, amountsBidWU.amountY, amountsBidWU.feeX, amountsBidWU.feeY) = limitOrderManager
            .getCurrentAmounts(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.BID, bidIdWU, bob);

        vm.startPrank(carol);
        limitOrderManager.executeOrders(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askIdLW);
        limitOrderManager.executeOrders(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.BID, bidIdWU);
        vm.stopPrank();

        vm.startPrank(alice);
        limitOrderManager.claimOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidIdLW);
        limitOrderManager.claimOrder(wnative, usdc, binStepWU, ILimitOrderManager.OrderType.ASK, askIdWU);
        vm.stopPrank();

        vm.startPrank(bob);
        limitOrderManager.claimOrder(link, IERC20(address(0)), binStepLW, ILimitOrderManager.OrderType.ASK, askIdLW);
        limitOrderManager.claimOrder(IERC20(address(0)), usdc, binStepWU, ILimitOrderManager.OrderType.BID, bidIdWU);
        vm.stopPrank();

        assertEq(link.balanceOf(alice), amountsBidLW.amountX - amountsBidLW.feeX, "test_OrderMultipleUsers::2");
        assertEq(amountsBidLW.amountY + amountsBidLW.feeY, 0, "test_OrderMultipleUsers::2");
        assertEq(amountsAskWU.amountX + amountsAskWU.feeX, 0, "test_OrderMultipleUsers::3");
        assertEq(usdc.balanceOf(alice), amountsAskWU.amountY - amountsAskWU.feeY, "test_OrderMultipleUsers::4");

        assertEq(amountsAskLW.amountX + amountsAskLW.feeX, 0, "test_OrderMultipleUsers::5");
        assertEq(amountsBidWU.amountY + amountsBidWU.feeY, 0, "test_OrderMultipleUsers::6");
        assertEq(
            bob.balance,
            amountsAskLW.amountY + amountsBidWU.amountX - amountsBidWU.feeX - amountsAskLW.feeY,
            "test_OrderMultipleUsers::7"
        );

        assertEq(link.balanceOf(carol), amountsBidLW.feeX + amountsAskLW.feeX, "test_OrderMultipleUsers::8");
        assertEq(
            wnative.balanceOf(carol),
            amountsBidWU.feeX + amountsAskWU.feeX + amountsAskLW.feeY + amountsBidLW.feeY,
            "test_OrderMultipleUsers::9"
        );
        assertEq(usdc.balanceOf(carol), amountsBidWU.feeY + amountsAskWU.feeY, "test_OrderMultipleUsers::10");
    }

    function test_BatchPlaceOrdersWithFailedOrders() public {
        uint24 idLW = linkWavax.getActiveId() - 1;
        uint24 idWU = wavaxUsdc.getActiveId() - 1;

        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](4);

        params[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: idLW,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: wnative,
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: idLW,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParams({
            tokenX: wnative,
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: idWU,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParams({
            tokenX: wnative,
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: idWU,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(wnative), alice, 2e18);
        deal(address(usdc), alice, 2e18);

        wnative.approve(address(limitOrderManager), type(uint256).max);
        usdc.approve(address(limitOrderManager), type(uint256).max);

        (bool[] memory successes,) = limitOrderManager.batchPlaceOrders(params);
        vm.stopPrank();

        assertTrue(successes[0], "test_BatchPlaceOrdersWithFailedOrders::1");
        assertFalse(successes[1], "test_BatchPlaceOrdersWithFailedOrders::2");
        assertTrue(successes[2], "test_BatchPlaceOrdersWithFailedOrders::3");
        assertFalse(successes[3], "test_BatchPlaceOrdersWithFailedOrders::4");

        assertEq(wnative.balanceOf(alice), 1e18, "test_BatchPlaceOrdersWithFailedOrders::5");
        assertEq(usdc.balanceOf(alice), 1e18, "test_BatchPlaceOrdersWithFailedOrders::5");
    }

    function test_BatchPlaceOrdersSamePairWithFailedOrders() public {
        uint24 bidId = linkWavax.getActiveId() - 1;
        uint24 askId = linkWavax.getActiveId() + 1;

        ILimitOrderManager.PlaceOrderParamsSamePair[] memory params =
            new ILimitOrderManager.PlaceOrderParamsSamePair[](4);

        params[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: askId,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: bidId,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(address(wnative), alice, 2e18);
        deal(address(link), alice, 2e18);

        wnative.approve(address(limitOrderManager), type(uint256).max);
        link.approve(address(limitOrderManager), type(uint256).max);

        (bool[] memory successes,) = limitOrderManager.batchPlaceOrdersSamePair(link, wnative, binStepLW, params);
        vm.stopPrank();

        assertFalse(successes[0], "test_BatchPlaceOrdersSamePairWithFailedOrders::1");
        assertFalse(successes[1], "test_BatchPlaceOrdersSamePairWithFailedOrders::2");
        assertTrue(successes[2], "test_BatchPlaceOrdersSamePairWithFailedOrders::3");
        assertTrue(successes[3], "test_BatchPlaceOrdersSamePairWithFailedOrders::4");

        assertEq(link.balanceOf(alice), 1e18, "test_BatchPlaceOrdersSamePairWithFailedOrders::5");
        assertEq(wnative.balanceOf(alice), 1e18, "test_BatchPlaceOrdersSamePairWithFailedOrders::6");
    }

    function test_BatchPlaceNativeOrdersWithFailedOrders() public {
        uint24 idLW = linkWavax.getActiveId() - 1;
        uint24 idWU = wavaxUsdc.getActiveId() + 1;

        ILimitOrderManager.PlaceOrderParams[] memory params = new ILimitOrderManager.PlaceOrderParams[](4);

        params[0] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: idLW,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParams({
            tokenX: link,
            tokenY: IERC20(address(0)),
            binStep: binStepLW,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: idLW,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.BID,
            binId: idWU,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParams({
            tokenX: IERC20(address(0)),
            tokenY: usdc,
            binStep: binStepWU,
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: idWU,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(alice, 4 ether);

        (bool[] memory successes,) = limitOrderManager.batchPlaceOrders{value: 4 ether}(params);
        vm.stopPrank();

        assertTrue(successes[0], "test_BatchPlaceOrdersWithFailedOrders::1");
        assertFalse(successes[1], "test_BatchPlaceOrdersWithFailedOrders::2");
        assertFalse(successes[2], "test_BatchPlaceOrdersWithFailedOrders::3");
        assertTrue(successes[3], "test_BatchPlaceOrdersWithFailedOrders::4");

        assertEq(alice.balance, 2 ether, "test_BatchPlaceOrdersWithFailedOrders::5");
    }

    function test_BatchPlaceNativeOrdersSamePairWithFailedOrders() public {
        uint24 bidId = linkWavax.getActiveId() - 1;
        uint24 askId = linkWavax.getActiveId() + 1;

        ILimitOrderManager.PlaceOrderParamsSamePair[] memory params =
            new ILimitOrderManager.PlaceOrderParamsSamePair[](4);

        params[0] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: askId,
            amount: 1e18
        });

        params[1] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: bidId,
            amount: 1e18
        });

        params[2] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.BID,
            binId: bidId,
            amount: 1e18
        });

        params[3] = ILimitOrderManager.PlaceOrderParamsSamePair({
            orderType: ILimitOrderManager.OrderType.ASK,
            binId: askId,
            amount: 1e18
        });

        vm.startPrank(alice);
        deal(alice, 2e18);
        deal(address(link), alice, 2e18);

        link.approve(address(limitOrderManager), type(uint256).max);

        (bool[] memory successes,) =
            limitOrderManager.batchPlaceOrdersSamePair{value: 2 ether}(link, IERC20(address(0)), binStepLW, params);
        vm.stopPrank();

        assertFalse(successes[0], "test_BatchPlaceOrdersSamePairWithFailedOrders::1");
        assertFalse(successes[1], "test_BatchPlaceOrdersSamePairWithFailedOrders::2");
        assertTrue(successes[2], "test_BatchPlaceOrdersSamePairWithFailedOrders::3");
        assertTrue(successes[3], "test_BatchPlaceOrdersSamePairWithFailedOrders::4");

        assertEq(link.balanceOf(alice), 1e18, "test_BatchPlaceOrdersSamePairWithFailedOrders::5");
        assertEq(alice.balance, 1e18, "test_BatchPlaceOrdersSamePairWithFailedOrders::6");
    }

    function test_FeesOnExecutionForBidOrder() public {
        uint24 bidId = linkWavax.getActiveId() - 1;
        uint256 bidPrice = PriceHelper.getPriceFromId(bidId, binStepLW);

        uint256 amountIn = 1e18;

        deal(address(wnative), address(this), amountIn);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, amountIn);

        uint256 fee;
        {
            uint16 baseFactor = 10_000;
            uint16 protocolShare = 2500;

            vm.prank(lbFactory.owner());
            lbFactory.setFeesParametersOnPair(link, wnative, binStepLW, baseFactor, 0, 0, 0, 0, protocolShare, 0);

            fee = uint256(baseFactor) * binStepLW * (10_000 - protocolShare) * 1e6;
        }

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        assertEq(amountX, 0, "test_FeesOnExecutionForBidOrder::1");
        assertEq(feeX, 0, "test_FeesOnExecutionForBidOrder::2");
        assertApproxEqAbs(amountY, amountIn, 1, "test_FeesOnExecutionForBidOrder::3");
        assertEq(feeY, amountIn * fee / (fee + 1e18), "test_FeesOnExecutionForBidOrder::4");

        swapNbBins(linkWavax, true, 2);

        uint256 minAmountReceived = amountIn * 2 ** 128 / bidPrice;

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.BID, bidId, address(this)
        );

        assertEq(amountY, 0, "test_FeesOnExecutionForBidOrder::5");
        assertEq(feeY, 0, "test_FeesOnExecutionForBidOrder::6");
        assertGe(amountX, minAmountReceived, "test_FeesOnExecutionForBidOrder::7");
        assertGe(feeX, minAmountReceived * fee / 1e18, "test_FeesOnExecutionForBidOrder::8");
    }

    function test_FeesOnExecutionForAskOrder() public {
        uint24 askId = linkWavax.getActiveId() + 1;
        uint256 bidPrice = PriceHelper.getPriceFromId(askId, binStepLW);

        uint256 amountIn = 1e18;

        deal(address(link), address(this), amountIn);
        limitOrderManager.placeOrder(link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, amountIn);

        uint256 fee;
        {
            uint16 baseFactor = 10_000;
            uint16 protocolShare = 2500;

            vm.prank(lbFactory.owner());
            lbFactory.setFeesParametersOnPair(link, wnative, binStepLW, baseFactor, 0, 0, 0, 0, protocolShare, 0);

            fee = uint256(baseFactor) * binStepLW * (10_000 - protocolShare) * 1e6;
        }

        (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        assertEq(amountY, 0, "test_FeesOnExecutionForAskOrder::1");
        assertEq(feeY, 0, "test_FeesOnExecutionForAskOrder::2");
        assertApproxEqAbs(amountX, amountIn, 1, "test_FeesOnExecutionForAskOrder::3");
        assertEq(feeX, amountIn * fee / (fee + 1e18), "test_FeesOnExecutionForAskOrder::4");

        swapNbBins(linkWavax, false, 2);

        uint256 minAmountReceived = (amountIn * bidPrice) >> 128;

        (amountX, amountY, feeX, feeY) = limitOrderManager.getCurrentAmounts(
            link, wnative, binStepLW, ILimitOrderManager.OrderType.ASK, askId, address(this)
        );

        assertEq(amountX, 0, "test_FeesOnExecutionForAskOrder::5");
        assertEq(feeX, 0, "test_FeesOnExecutionForAskOrder::6");
        assertGe(amountY, minAmountReceived, "test_FeesOnExecutionForAskOrder::7");
        assertGe(feeY, minAmountReceived * fee / 1e18, "test_FeesOnExecutionForAskOrder::8");
    }

    receive() external payable {}
}
