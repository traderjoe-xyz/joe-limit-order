// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";

/**
 * @title Limit Order Manager Interface
 * @author Trader Joe
 * @notice Interface to interact with the Limit Order Manager contract
 */
interface ILimitOrderManager {
    error LimitOrderManager__ZeroAddress();
    error LimitOrderManager__ZeroAmount();
    error LimitOrderManager__TransferFailed();
    error LimitOrderManager__InvalidPair();
    error LimitOrderManager__InvalidBatchLength();
    error LimitOrderManager__InvalidTokenOrder();
    error LimitOrderManager__InvalidNativeAmount();
    error LimitOrderManager__OrderAlreadyExecuted();
    error LimitOrderManager__OrderNotClaimable();
    error LimitOrderManager__OrderNotPlaced();
    error LimitOrderManager__OrderNotExecutable();
    error LimitOrderManager__OnlyWNative();

    /**
     * @dev Order type,
     * BID: buy tokenX with tokenY
     * ASK: sell tokenX for tokenY
     */
    enum OrderType {
        BID,
        ASK
    }

    /**
     * @dev Order structure:
     * - positionId: The position id of the order, used to identify to which position the order belongs
     * - liquidity: The amount of liquidity in the order
     */
    struct Order {
        uint256 positionId;
        uint256 liquidity;
    }

    /**
     * @dev Positions structure:
     * - lastId: The last position id
     * - at: The positions, indexed by position id
     * We use a mapping instead of an array as we need to be able to query the last position id
     * to know if a position exists or not, which would be impossible with an array.
     */
    struct Positions {
        uint256 lastId;
        mapping(uint256 => Position) at;
    }

    /**
     * @dev Position structure:
     * - liquidity: The amount of liquidity in the position, it is the sum of the liquidity of all orders
     * - amount: The amount of token after the execution of the position, once the orders are executed
     * - withdrawn: Whether the position has been withdrawn or not
     */
    struct Position {
        uint256 liquidity;
        uint128 amount;
        bool withdrawn;
    }

    /**
     * @dev Place order params structure, used to place multiple orders in a single transaction.
     */
    struct PlaceOrderParams {
        IERC20 tokenX;
        IERC20 tokenY;
        uint16 binStep;
        OrderType orderType;
        uint24 binId;
        uint256 amount;
    }

    /**
     * @dev Order params structure, used to cancel, claim and execute multiple orders in a single transaction.
     */
    struct OrderParams {
        IERC20 tokenX;
        IERC20 tokenY;
        uint16 binStep;
        OrderType orderType;
        uint24 binId;
    }

    /**
     * @dev Place order params structure for the same LB pair, used to place multiple orders in a single transaction
     * for the same LB pair
     */
    struct PlaceOrderParamsSamePair {
        OrderType orderType;
        uint24 binId;
        uint256 amount;
    }

    /**
     * @dev Order params structure for the same LB pair, used to cancel, claim and execute multiple orders in a single
     * transaction for the same LB pair
     */
    struct OrderParamsSamePair {
        OrderType orderType;
        uint24 binId;
    }

    event OrderPlaced(
        address indexed user,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event OrderCancelled(
        address indexed user,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event OrderClaimed(
        address indexed user,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event OrderExecuted(
        address indexed sender,
        ILBPair indexed lbPair,
        uint24 indexed binId,
        OrderType orderType,
        uint256 positionId,
        uint256 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    event ExecutionFeePaid(address indexed executor, IERC20 tokenX, IERC20 tokenY, uint256 amountX, uint256 amountY);

    function name() external pure returns (string memory);

    function getFactory() external view returns (ILBFactory);

    function getOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, address user)
        external
        view
        returns (Order memory);

    function getLastPositionId(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        returns (uint256);

    function getPosition(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        uint256 positionId
    ) external view returns (Position memory);

    function isOrderExecutable(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        view
        returns (bool);

    function getCurrentAmounts(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderType orderType,
        uint24 binId,
        address user
    ) external view returns (uint256 amountX, uint256 amountY, uint256 feeX, uint256 feeY);

    function getExecutionFee(IERC20 tokenX, IERC20 tokenY, uint16 binStep) external view returns (uint256 fee);

    function placeOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId, uint256 amount)
        external
        payable
        returns (bool orderPlaced, uint256 orderPositionId);

    function cancelOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        returns (uint256 orderPositionId);

    function claimOrder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        returns (uint256 orderPositionId);

    function executeOrders(IERC20 tokenX, IERC20 tokenY, uint16 binStep, OrderType orderType, uint24 binId)
        external
        returns (bool orderExecuted, uint256 positionId);

    function batchPlaceOrders(PlaceOrderParams[] calldata orders)
        external
        payable
        returns (bool[] memory orderPlaced, uint256[] memory positionIds);

    function batchCancelOrders(OrderParams[] calldata orders) external returns (uint256[] memory positionIds);

    function batchClaimOrders(OrderParams[] calldata orders) external returns (uint256[] memory positionIds);

    function batchExecuteOrders(OrderParams[] calldata orders)
        external
        returns (bool[] memory orderExecuted, uint256[] memory positionIds);

    function batchPlaceOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        PlaceOrderParamsSamePair[] calldata orders
    ) external payable returns (bool[] memory orderPlaced, uint256[] memory positionIds);

    function batchCancelOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external returns (uint256[] memory positionIds);

    function batchClaimOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external returns (uint256[] memory positionIds);

    function batchExecuteOrdersSamePair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        OrderParamsSamePair[] calldata orders
    ) external returns (bool[] memory orderExecuted, uint256[] memory positionIds);
}
