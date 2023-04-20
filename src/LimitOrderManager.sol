// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {LiquidityConfigurations} from "joe-v2/libraries/math/LiquidityConfigurations.sol";
import {PackedUint128Math} from "joe-v2/libraries/math/PackedUint128Math.sol";
import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {SafeCast} from "joe-v2/libraries/math/SafeCast.sol";

import {ILimitOrderManager} from "./interfaces/ILimitOrderManager.sol";

/**
 * @title Limit Order Manager
 * @author Trader Joe
 * @notice This contracts allows users to place limit orders using the Liquidity Book protocol.
 * It allows to create orders for any Liquidity Book pair V2.1.
 *
 * The flow of the Limit Order Manager is the following:
 * - Users create orders for a specific pair, type (bid or ask), price (bin id) and amount
 *  (in token Y for bid orders and token X for ask orders) which will be added to the liquidity book pair.
 * - Users can cancel orders, which will remove the liquidity from the liquidity book pair according to the order amount
 * and send the token amounts back to the user (the amounts depend on the bin composition).
 * - Users can execute orders, which will remove the liquidity from the order and send the token to the
 * Limit Order Manager contract.
 * - Users can claim their executed orders, which will send a portion of the token received from the execution
 * to the user (the share depends on the total executed amount of the orders).
 *
 * Users can place orders using the `placeOrder` function by specifying the following parameters:
 * - `tokenX`: the token X of the liquidity book pair
 * - `tokenY`: the token Y of the liquidity book pair
 * - `binStep`: the bin step of the liquidity book pair
 * - `orderType`: the order type (bid or ask)
 * - `binId`: the bin id of the order, which is the price of the order
 * - `amount`: the amount of token to be used for the order, in token Y for bid orders and token X for ask orders
 * Orders can't be placed in the active bin id. Bid orders need to be placed in a bin id greater than the active id,
 * while ask orders need to be placed in a bin id lower than the active bin id.
 *
 * Users can cancel orders using the `cancelOrder` function by specifying the same parameters as for `placeOrder` but
 * without the `amount` parameter.
 * If the order is already executed, it can't be cancelled, and user will need to claim the filled amount.
 * If the user is trying to cancel an order that is inside the active bin id, he may receive a partially filled order,
 * according to the active bin composition.
 *
 * Users can claim orders using the `claimOrder` function by specifying the same parameters as for `placeOrder` but
 * without the `amount` parameter.
 * If the order is not already executed, but that it can be executed, it will be executed first and then claimed.
 * If the order isn't executable, it can't be claimed and the transaction will revert.
 * If the order is already executed, the user will receive the filled amount.
 *
 * Users can execute orders using the `executeOrder` function by specifying the same parameters as for `placeOrder` but
 * without the `amount` parameter.
 * If the order can't be executed or if it is already executed, the transaction will revert.
 */
contract LimitOrderManager is ReentrancyGuard, ILimitOrderManager {
    using SafeERC20 for IERC20;
    using PackedUint128Math for bytes32;
    using Uint256x256Math for uint256;
    using SafeCast for uint256;

    ILBFactory private immutable _factory;

    /**
     * @dev Mapping of order key (pair, order type, bin id) to positions.
     */
    mapping(bytes32 => Positions) private _positions;

    /**
     * @dev Mapping of user address to mapping of order key (pair, order type, bin id) to order.
     */
    mapping(address => mapping(bytes32 => Order)) private _orders;

    /**
     * @notice Constructor of the Limit Order Manager.
     * @param factory The address of the Liquidity Book factory.
     */
    constructor(ILBFactory factory) {
        if (address(factory) == address(0)) revert LimitOrderManager__ZeroAddress();

        _factory = factory;
    }

    /**
     * @notice Returns the name of the Limit Order Manager.
     * @return The name of the Limit Order Manager.
     */
    function name() external pure override returns (string memory) {
        return "Joe Limit Order Manager";
    }

    /**
     * @notice Returns the address of the Liquidity Book factory.
     * @return The address of the Liquidity Book factory.
     */
    function getFactory() external view override returns (ILBFactory) {
        return _factory;
    }

    /**
     * @notice Returns the order of the user for the given parameters.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param user The user address.
     * @return The order of the user for the given parameters.
     */
    function getOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, address user)
        external
        view
        override
        returns (Order memory)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _orders[user][_getOrderKey(lbPair, orderType, binId)];
    }

    /**
     * @notice Returns the last position id for the given parameters.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return The last position id for the given parameters.
     */
    function getLastPositionId(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        override
        returns (uint256)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);
        return _positions[_getOrderKey(lbPair, orderType, binId)].lastId;
    }

    /**
     * @notice Returns the position for the given parameters.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param positionId The position id.
     * @return The position for the given parameters.
     */
    function getPosition(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        uint256 positionId
    ) external view override returns (Position memory) {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);
        return _positions[_getOrderKey(lbPair, orderType, binId)].at[positionId];
    }

    /**
     * @notice Return whether the order is executable or not.
     * Will return false if the order is already executed or if it is not executable.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return Whether the order is executable or not.
     */
    function isOrderExecutable(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        override
        returns (bool)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        // Get the order key
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the positions for the order key to get the last position id
        Positions storage positions = _positions[orderKey];
        uint256 positionId = positions.lastId;

        // Get the position at the last position id
        Position storage position = positions.at[positionId];

        // Return whether the position is executable or not, that is, if the position id is greater than 0,
        // the position is not already withdrawn and the order is executable
        return (positionId > 0 && !position.withdrawn && _isOrderExecutable(lbPair, orderType, binId));
    }

    /**
     * @notice Returns the current amounts of the order for the given parameters.
     * Depending on the current bin id, the amounts might fluctuate.
     * The amount returned will be the value that the user will receive if the order is cancelled.
     * If it's fully converted to the other token, then it's the amount that the user will receive after the order
     * is claimed.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param user The user address.
     * @return amountX The amount of token X.
     * @return amountY The amount of token Y.
     */
    function getCurrentAmounts(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        address user
    ) external view override returns (uint256 amountX, uint256 amountY) {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        Order storage order = _orders[user][orderKey];
        Position storage position = _positions[orderKey].at[order.positionId];

        uint256 orderLiquidity = order.liquidity;

        if (position.withdrawn) {
            uint256 amount = orderLiquidity.mulDivRoundDown(position.amount, position.liquidity);

            return orderType == OrderType.BID ? (amount, uint256(0)) : (uint256(0), amount);
        }

        uint256 totalLiquidity = lbPair.totalSupply(binId);
        if (totalLiquidity == 0) return (0, 0);

        (uint256 binReserveX, uint256 binReserveY) = lbPair.getBin(binId);

        amountX = orderLiquidity.mulDivRoundDown(binReserveX, totalLiquidity);
        amountY = orderLiquidity.mulDivRoundDown(binReserveY, totalLiquidity);
    }

    /**
     * @notice Place an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param amount The amount of the order.
     * @return orderPositionId The position id of the order.
     */
    function placeOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, uint256 amount)
        external
        override
        nonReentrant
        returns (uint256 orderPositionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        (IERC20 tokenIn, IERC20 tokenOut) = orderType == OrderType.BID ? (tokenY, tokenX) : (tokenX, tokenY);

        return _placeOrder(lbPair, tokenIn, tokenOut, amount, orderType, binId);
    }

    /**
     * @notice Cancel an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function cancelOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        override
        nonReentrant
        returns (uint256 orderPositionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _cancelOrder(lbPair, tokenX, tokenY, orderType, binId);
    }

    /**
     * @notice Claim an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function claimOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        override
        nonReentrant
        returns (uint256 orderPositionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _claimOrder(lbPair, tokenX, tokenY, orderType, binId);
    }

    /**
     * @notice Execute an order.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return positionId The position id.
     */
    function executeOrders(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        override
        nonReentrant
        returns (uint256 positionId)
    {
        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        return _executeOrders(lbPair, tokenX, tokenY, orderType, binId);
    }

    /**
     * @notice Place multiple orders.
     * @param orders The orders to place.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchPlaceOrders(PlaceOrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            PlaceOrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            (IERC20 tokenIn, IERC20 tokenOut) =
                order.orderType == OrderType.BID ? (order.tokenY, order.tokenX) : (order.tokenX, order.tokenY);

            orderPositionIds[i] = _placeOrder(lbPair, tokenIn, tokenOut, order.amount, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancel multiple orders.
     * @param orders The orders to cancel.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchCancelOrders(OrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            OrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            orderPositionIds[i] = _cancelOrder(lbPair, order.tokenX, order.tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim multiple orders.
     * @param orders The orders to claim.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchClaimOrders(OrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            OrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            orderPositionIds[i] = _claimOrder(lbPair, order.tokenX, order.tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Execute multiple orders.
     * @param orders The orders to execute.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchExecuteOrders(OrderParams[] calldata orders)
        external
        override
        nonReentrant
        returns (uint256[] memory orderPositionIds)
    {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        for (uint256 i; i < orders.length;) {
            OrderParams calldata order = orders[i];

            ILBPair lbPair = _getLBPair(order.tokenX, order.tokenY, order.binStep);

            orderPositionIds[i] = _executeOrders(lbPair, order.tokenX, order.tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Place multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to place.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchPlaceOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        PlaceOrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            PlaceOrderParamsSamePair calldata order = orders[i];

            (IERC20 tokenIn, IERC20 tokenOut) = order.orderType == OrderType.BID ? (tokenY, tokenX) : (tokenX, tokenY);

            orderPositionIds[i] = _placeOrder(lbPair, tokenIn, tokenOut, order.amount, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Cancel multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to cancel.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchCancelOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            OrderParamsSamePair calldata order = orders[i];

            orderPositionIds[i] = _cancelOrder(lbPair, tokenX, tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Claim multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to claim.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchClaimOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            OrderParamsSamePair calldata order = orders[i];

            orderPositionIds[i] = _claimOrder(lbPair, tokenX, tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Execute multiple orders for the same pair.
     * @dev This function saves a bit of gas, as it avoids calling multiple time the _getLBPair function.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @param orders The orders to execute.
     * @return orderPositionIds The position ids of the orders.
     */
    function batchExecuteOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external override nonReentrant returns (uint256[] memory orderPositionIds) {
        if (orders.length == 0) revert LimitOrderManager__InvalidBatchLength();

        orderPositionIds = new uint256[](orders.length);

        ILBPair lbPair = _getLBPair(tokenX, tokenY, binStep);

        for (uint256 i; i < orders.length;) {
            OrderParamsSamePair calldata order = orders[i];

            orderPositionIds[i] = _executeOrders(lbPair, tokenX, tokenY, order.orderType, order.binId);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Get the liquidity book pair address from the factory.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binStep The bin step of the liquidity book pair.
     * @return lbPair The liquidity book pair.
     */
    function _getLBPair(IERC20 tokenX, IERC20 tokenY, uint16 binStep) private view returns (ILBPair lbPair) {
        lbPair = _factory.getLBPairInformation(tokenX, tokenY, binStep).LBPair;

        // Check if the liquidity book pair is valid, that is, if the lbPair address is not 0.
        if (address(lbPair) == address(0)) revert LimitOrderManager__InvalidPair();

        // Check if the token X of the liquidity book pair is the same as the token X of the order.
        // We revert here because if the tokens are in the wrong order, then the price of the order will be wrong.
        if (lbPair.getTokenX() != tokenX) revert LimitOrderManager__InvalidTokenOrder();
    }

    /**
     * @dev Return whether the order is valid or not.
     * An order is valid if the order type is bid and the bin id is greater than or equal to the active id,
     * or if the order type is ask and the bin id is less than or equal to the active id. This is to prevent adding
     * orders to the active bin and to add liquidity to a bin that can't receive the token sent.
     * @param lbPair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return valid Whether the order is valid or not.
     */
    function _isOrderValid(ILBPair lbPair, OrderType orderType, uint24 binId) private view returns (bool) {
        uint24 activeId = lbPair.getActiveId();
        return ((orderType == OrderType.BID && binId < activeId) || (orderType == OrderType.ASK && binId > activeId));
    }

    /**
     * @dev Return whether the order is executable or not.
     * An order is executable if the order type is bid and the bin id is less than or equal to the active id,
     * or if the order type is ask and the bin id is greater than or equal to the active id. This is to only allow
     * executing orders that are fully filled.
     * @param lbPair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return executable Whether the order is executable or not.
     */
    function _isOrderExecutable(ILBPair lbPair, OrderType orderType, uint24 binId) private view returns (bool) {
        uint24 activeId = lbPair.getActiveId();
        return ((orderType == OrderType.BID && binId > activeId) || (orderType == OrderType.ASK && binId < activeId));
    }

    /**
     * @dev Place an order.
     * If the user already have an order with the same parameters and that it's not executed yet, instead of creating a
     * new order, the amount of the previous order is increased by the amount of the new order.
     * If the user already have an order with the same parameters and that it's executed, the order is claimed if
     * it was not claimed yet and a new order is created  overwriting the previous one.
     * @param lbPair The liquidity book pair.
     * @param tokenIn The token in of the order.
     * @param tokenOut The token out of the order.
     * @param amount The amount of the order.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function _placeOrder(
        ILBPair lbPair,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amount,
        OrderType orderType,
        uint24 binId
    ) private returns (uint256 orderPositionId) {
        // Check if the order is valid.
        if (!_isOrderValid(lbPair, orderType, binId)) revert LimitOrderManager__InvalidOrder();

        // Deposit the amount sent by the user to the liquidity book pair.
        (uint256 amountX, uint256 amountY, uint256 liquidity) =
            _depositToLBPair(lbPair, tokenIn, orderType, binId, amount);

        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the position of the order.
        Positions storage positions = _positions[orderKey];

        // Get the last position id and the last position.
        uint256 positionId = positions.lastId;
        Position storage position = positions.at[positionId];

        // If the last position id is 0 or the last position is withdrawn, create a new position.
        if (positionId == 0 || position.withdrawn) {
            ++positionId;
            positions.lastId = positionId;

            position = positions.at[positionId];
        }

        // Update the liquidity of the position.
        position.liquidity += liquidity;

        // Get the current user order.
        Order storage order = _orders[msg.sender][orderKey];

        // Get the position id of the current user order.
        orderPositionId = order.positionId;

        // If the position id of the order is smaller than the current position id, the order needs to be claimed,
        // unless the position id of the order is 0.
        if (orderPositionId < positionId) {
            // If the position id of the order is not 0, claim the order from the position.
            if (orderPositionId != 0) {
                _claimOrderFromPosition(positions.at[orderPositionId], order, tokenOut, orderPositionId, orderKey);
            }

            // Set the position id of the order to the current position id.
            orderPositionId = positionId;
            order.positionId = orderPositionId;
        }

        // Update the order liquidity.
        order.liquidity += liquidity;

        emit OrderPlaced(msg.sender, lbPair, binId, orderType, positionId, liquidity, amountX, amountY);
    }

    /**
     * @dev Claim an order.
     * If the order is not claimable, the function reverts.
     * If the order is not claimable but executable, the order is first executed and then claimed.
     * If the order is claimable, the order is claimed and the user receives the tokens.
     * @param lbPair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function _claimOrder(ILBPair lbPair, IERC20 tokenX, IERC20 tokenY, OrderType orderType, uint24 binId)
        private
        returns (uint256 orderPositionId)
    {
        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the current user order.
        Order storage order = _orders[msg.sender][orderKey];

        // Get the position id of the current user order.
        orderPositionId = order.positionId;

        // If the position id of the order is 0, the order is not claimable, therefore revert.
        if (orderPositionId == 0) revert LimitOrderManager__OrderNotClaimable();

        // Get the position of the order.
        Position storage position = _positions[orderKey].at[orderPositionId];

        // If the position is not withdrawn, try to execute the order.
        if (!position.withdrawn) _executeOrders(lbPair, tokenX, tokenY, orderType, binId);

        // Claim the order from the position, which will transfer the amount of the filled order to the user.
        _claimOrderFromPosition(
            position, order, orderType == OrderType.BID ? tokenX : tokenY, orderPositionId, orderKey
        );
    }

    /**
     * @dev Claim an order from a position.
     * This function does not check if the order is claimable or not, therefore it needs to be called by a function
     * that does the necessary checks.
     * @param position The position of the order.
     * @param order The order.
     * @param token The token of the order.
     * @param positionId The position id of the order.
     * @param orderKey The order key.
     */
    function _claimOrderFromPosition(
        Position storage position,
        Order storage order,
        IERC20 token,
        uint256 positionId,
        bytes32 orderKey
    ) private {
        // Get the order liquidity.
        uint256 orderLiquidity = order.liquidity;

        // Set the order liquidity and position id to 0.
        order.positionId = 0;
        order.liquidity = 0;

        // Calculate the amount of the order.
        uint256 amount = orderLiquidity.mulDivRoundDown(position.amount, position.liquidity);

        // Transfer the amount of the order to the user.
        token.safeTransfer(msg.sender, amount);

        // Get the order key components (liquidity book pair, order type, bin id) from the order key to emit the event.
        (ILBPair lbPair, OrderType orderType, uint24 binId) = _getOrderKeyComponents(orderKey);
        (uint256 amountX, uint256 amountY) = orderType == OrderType.BID ? (amount, uint256(0)) : (uint256(0), amount);

        emit OrderClaimed(msg.sender, lbPair, binId, orderType, positionId, orderLiquidity, amountX, amountY);
    }

    /**
     * @dev Cancel an order.
     * If the order is not placed, the function reverts.
     * If the order is already executed, the function reverts.
     * If the order is placed, the order is cancelled and the liquidity is withdrawn from the liquidity book pair.
     * The liquidity is then transferred back to the user (the amounts depend on the bin composition).
     * @param lbPair The liquidity book pair.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return orderPositionId The position id of the order.
     */
    function _cancelOrder(ILBPair lbPair, IERC20 tokenX, IERC20 tokenY, OrderType orderType, uint24 binId)
        private
        returns (uint256 orderPositionId)
    {
        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the current user order.
        Order storage order = _orders[msg.sender][orderKey];

        // Get the position id of the current user order.
        orderPositionId = order.positionId;

        // If the position id of the order is 0, the order is not placed, therefore revert.
        if (orderPositionId == 0) revert LimitOrderManager__OrderNotPlaced();

        // Get the position of the order.
        Position storage position = _positions[orderKey].at[orderPositionId];

        // If the position is withdrawn, the order is already executed, therefore revert.
        if (position.withdrawn) revert LimitOrderManager__OrderAlreadyExecuted();

        // Get the order liquidity.
        uint256 orderLiquidity = order.liquidity;

        // Set the order liquidity and position id to 0.
        order.positionId = 0;
        order.liquidity = 0;

        // Decrease the position liquidity by the order liquidity.
        position.liquidity -= orderLiquidity;

        // Withdraw the liquidity from the liquidity book pair.
        (uint256 amountX, uint256 amountY) =
            _withdrawFromLBPair(lbPair, tokenX, tokenY, binId, orderLiquidity, msg.sender);

        emit OrderCancelled(msg.sender, lbPair, binId, orderType, orderPositionId, orderLiquidity, amountX, amountY);
    }

    /**
     * @dev Execute the orders of a lbPair, order type and bin id.
     * If the bin is not executable, the function reverts.
     * If the bin is executable, the function executes the orders of the bin.
     * @param lbPair The liquidity book pair.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return positionId The position id of the executed orders.
     */
    function _executeOrders(ILBPair lbPair, IERC20 tokenX, IERC20 tokenY, OrderType orderType, uint24 binId)
        private
        returns (uint256 positionId)
    {
        // Check if the bin is executable.
        if (!_isOrderExecutable(lbPair, orderType, binId)) revert LimitOrderManager__OrderNotExecutable();

        // Get the order key.
        bytes32 orderKey = _getOrderKey(lbPair, orderType, binId);

        // Get the positions of the order.
        Positions storage positions = _positions[orderKey];

        // Get the last position id of the order.
        positionId = positions.lastId;

        // If the position id is 0, there are no orders to execute, therefore revert.
        if (positionId == 0) revert LimitOrderManager__NoOrdersToExecute();

        // Get the last position of the order.
        Position storage position = _positions[orderKey].at[positionId];

        // If the position is withdrawn, the orders are already executed, therefore revert.
        if (position.withdrawn) revert LimitOrderManager__OrdersAlreadyExecuted();
        position.withdrawn = true;

        // Get the position liquidity.
        uint256 positionLiquidity = position.liquidity;

        // If the position liquidity is 0, there are no orders to execute, therefore revert.
        if (positionLiquidity == 0) revert LimitOrderManager__ZeroPositionLiquidity();

        // Withdraw the liquidity from the liquidity book pair.
        (uint128 amountX, uint128 amountY) =
            _withdrawFromLBPair(lbPair, tokenX, tokenY, binId, positionLiquidity, address(this));

        // If the order type is bid, the withdrawn liquidity is only composed of token X,
        // otherwise the withdrawn liquidity is only composed of token Y.
        position.amount = orderType == OrderType.BID ? amountX : amountY;

        emit OrderExecuted(msg.sender, lbPair, binId, orderType, positionId, positionLiquidity, amountX, amountY);
    }

    /**
     * @dev Deposit liquidity to a liquidity book pair.
     * @param lbPair The liquidity book pair.
     * @param token The token to deposit.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @param amount The amount of the token to deposit.
     * @return amountX The amount of token X deposited.
     * @return amountY The amount of token Y deposited.
     * @return liquidity The liquidity deposited.
     */
    function _depositToLBPair(ILBPair lbPair, IERC20 token, OrderType orderType, uint24 binId, uint256 amount)
        private
        returns (uint256 amountX, uint256 amountY, uint256 liquidity)
    {
        // If the amount is 0, revert.
        if (amount == 0) revert LimitOrderManager__ZeroAmount();

        // Get the liquidity configurations, which is just adding liquidity to a single bin.
        bytes32[] memory liquidityConfigurations = new bytes32[](1);

        (uint64 distributionX, uint64 distributionY) =
            orderType == OrderType.BID ? (uint64(0), 1e18) : (1e18, uint64(0));

        liquidityConfigurations[0] = LiquidityConfigurations.encodeParams(distributionX, distributionY, binId);

        // Send the amount of the token to the liquidity book pair.
        token.safeTransferFrom(msg.sender, address(lbPair), amount);

        // Mint the liquidity to the liquidity book pair.
        (bytes32 packedAmountIn, bytes32 packedAmountExcess, uint256[] memory liquidities) =
            lbPair.mint(address(this), liquidityConfigurations, msg.sender);

        // Get the amount of token X and token Y deposited, which is the amount of the token minus the excess
        // as it's sent back to the `msg.sender` directly.
        (amountX, amountY) = packedAmountIn.sub(packedAmountExcess).decode();

        // Get the liquidity deposited.
        liquidity = liquidities[0];
    }

    /**
     * @dev Withdraw liquidity from a liquidity book pair.
     * @param lbPair The liquidity book pair.
     * @param tokenX The token X of the liquidity book pair.
     * @param tokenY The token Y of the liquidity book pair.
     * @param binId The bin id of the order, which is the price of the order.
     * @param liquidity The liquidity to withdraw.
     * @param to The address to withdraw the liquidity to.
     * @return amountX The amount of token X withdrawn.
     * @return amountY The amount of token Y withdrawn.
     */
    function _withdrawFromLBPair(
        ILBPair lbPair,
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 binId,
        uint256 liquidity,
        address to
    ) private returns (uint128 amountX, uint128 amountY) {
        // Get the ids and amounts of the liquidity to burn.
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = binId;
        amounts[0] = liquidity;

        // Get the current balance of the token X and token Y.
        uint256 balanceX = tokenX.balanceOf(to);
        uint256 balanceY = tokenY.balanceOf(to);

        // Burn the liquidity from the liquidity book pair, sending the tokens directly to `to` address.
        lbPair.burn(address(this), to, ids, amounts);

        // Get the amount of token X and token Y withdrawn.
        amountX = (tokenX.balanceOf(to) - balanceX).safe128();
        amountY = (tokenY.balanceOf(to) - balanceY).safe128();
    }

    /**
     * @dev Get the order key.
     * The order key is composed of the liquidity book pair, the order type and the bin id, packed as follow:
     * - [255 - 96]: liquidity book pair address.
     * - [95 - 88]: order type (bid or ask)
     * - [87 - 24]: empty bits.
     * - [23 - 0]: bin id.
     * @param pair The liquidity book pair.
     * @param orderType The order type (bid or ask).
     * @param binId The bin id of the order, which is the price of the order.
     * @return key The order key.
     */
    function _getOrderKey(ILBPair pair, OrderType orderType, uint24 binId) private pure returns (bytes32 key) {
        assembly {
            key := shl(96, pair)
            key := or(key, shl(88, and(orderType, 0xff)))
            key := or(key, and(binId, 0xffffff))
        }
    }

    /**
     * @dev Get the order key components.
     * @param key The order key, packed as follow:
     * - [255 - 96]: liquidity book pair address.
     * - [95 - 88]: order type (bid or ask)
     * - [87 - 24]: empty bits.
     * - [23 - 0]: bin id.
     * @return pair The liquidity book pair.
     * @return orderType The order type (bid or ask).
     * @return binId The bin id of the order, which is the price of the order.
     */
    function _getOrderKeyComponents(bytes32 key)
        private
        pure
        returns (ILBPair pair, OrderType orderType, uint24 binId)
    {
        // Get the order key components from the order key.
        assembly {
            pair := shr(96, key)
            orderType := and(shr(88, key), 0xff)
            binId := and(key, 0xffffff)
        }
    }
}
