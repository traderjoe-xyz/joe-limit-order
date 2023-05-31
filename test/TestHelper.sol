// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/LimitOrderManager.sol";

contract TestHelper is Test {
    ILBFactory public constant lbFactory = ILBFactory(0x8e42f2F4101563bF679975178e880FD87d3eFd4e);

    ILBPair public constant lbPair = ILBPair(0xc0dFC065894B20d79AADe34A63b5651061b135Cc);
    IERC20 public constant tokenX = IERC20(0x5947BB275c521040051D82396192181b413227A3);
    IERC20 public constant tokenY = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant usdc = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    IWNATIVE public constant wnative = IWNATIVE(address(tokenY));
    uint16 public constant binStep = 10;

    LimitOrderManager public limitOrderManager;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("avalanche"), 30_721_730);

        limitOrderManager = new LimitOrderManager(lbFactory, wnative);

        vm.label(address(lbFactory), "lbFactory");
        vm.label(address(lbPair), "lbPair");
        vm.label(address(tokenX), "tokenX");
        vm.label(address(tokenY), "tokenY");

        tokenX.approve(address(limitOrderManager), type(uint256).max);
        tokenY.approve(address(limitOrderManager), type(uint256).max);
    }

    function swapNbBins(bool swapForY, uint24 nbBin) public {
        swapNbBins(lbPair, swapForY, nbBin);
    }

    function swapNbBins(ILBPair lbPair_, bool swapForY, uint24 nbBin) public {
        require(nbBin > 0, "TestHelper: nbBin must be > 0");

        IERC20 tokenX_ = lbPair_.getTokenX();
        IERC20 tokenY_ = lbPair_.getTokenY();

        uint24 id = activeId(lbPair_);
        uint128 reserve;

        for (uint24 i = 0; i <= nbBin; i++) {
            uint24 nextId = swapForY ? id - i : id + i;
            (uint128 binReserveX, uint128 binReserveY) = lbPair_.getBin(nextId);

            uint128 amount = swapForY ? binReserveY : binReserveX;

            if (i == nbBin) {
                amount /= 2;
            }

            reserve += amount;
        }

        (uint128 amountIn,,) = lbPair_.getSwapIn(reserve, swapForY);

        deal(address(swapForY ? tokenX_ : tokenY_), address(this), amountIn);

        (swapForY ? tokenX_ : tokenY_).transfer(address(lbPair_), amountIn);

        lbPair_.swap(swapForY, address(1));

        require(activeId(lbPair_) == (swapForY ? id - nbBin : id + nbBin), "TestHelper: invalid active bin");
    }

    function activeId() public view returns (uint24) {
        return activeId(lbPair);
    }

    function activeId(ILBPair lbPair_) public view returns (uint24) {
        return lbPair_.getActiveId();
    }
}
