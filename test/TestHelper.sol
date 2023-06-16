// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/LimitOrderManager.sol";

contract TestHelper is Test {
    ILBFactory public constant lbFactory = ILBFactory(0x8e42f2F4101563bF679975178e880FD87d3eFd4e);

    ILBPair public constant linkWavax = ILBPair(0xc0dFC065894B20d79AADe34A63b5651061b135Cc);
    uint16 public constant binStepLW = 10;

    ILBPair public constant wavaxUsdc = ILBPair(0xD446eb1660F766d533BeCeEf890Df7A69d26f7d1);
    uint16 public constant binStepWU = 20;

    IERC20 public constant link = IERC20(0x5947BB275c521040051D82396192181b413227A3);
    IERC20 public constant wnative = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant usdc = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);

    LimitOrderManager public limitOrderManager;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("avalanche"), 30_721_730);

        limitOrderManager = new LimitOrderManager(lbFactory, IWNATIVE(address(wnative)));

        vm.label(address(lbFactory), "lbFactory");
        vm.label(address(linkWavax), "linkWavax");
        vm.label(address(link), "link");
        vm.label(address(wnative), "wnative");

        link.approve(address(limitOrderManager), type(uint256).max);
        wnative.approve(address(limitOrderManager), type(uint256).max);
    }

    function swapNbBins(ILBPair lbPair, bool swapForY, uint24 nbBin) public {
        require(nbBin > 0, "TestHelper: nbBin must be > 0");

        IERC20 tokenX = lbPair.getTokenX();
        IERC20 tokenY = lbPair.getTokenY();

        uint24 id = lbPair.getActiveId();
        uint128 reserve;

        for (uint24 i = 0; i <= nbBin; i++) {
            uint24 nextId = swapForY ? id - i : id + i;
            (uint128 binReserveX, uint128 binReserveY) = lbPair.getBin(nextId);

            uint128 amount = swapForY ? binReserveY : binReserveX;

            if (i == nbBin) {
                amount /= 2;
            }

            reserve += amount;
        }

        (uint128 amountIn,,) = lbPair.getSwapIn(reserve, swapForY);

        deal(address(swapForY ? tokenX : tokenY), address(this), amountIn);

        (swapForY ? tokenX : tokenY).transfer(address(lbPair), amountIn);

        lbPair.swap(swapForY, address(1));

        require(lbPair.getActiveId() == (swapForY ? id - nbBin : id + nbBin), "TestHelper: invalid active bin");
    }
}
