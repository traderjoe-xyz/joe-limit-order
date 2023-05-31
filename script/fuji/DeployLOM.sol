// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "../../src/LimitOrderManager.sol";

contract DeployLOM is Script {
    ILBFactory constant lbFactory = ILBFactory(0x8e42f2F4101563bF679975178e880FD87d3eFd4e);
    IWNATIVE constant wnative = IWNATIVE(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);

    function run() public returns (LimitOrderManager limitOrderManager) {
        // Fork the network
        vm.createSelectFork(vm.rpcUrl("fuji"));

        // Get the public and private key of the deployer
        address deployer = vm.rememberKey(vm.envUint("DEPLOY_PRIVATE_KEY"));

        //Deploy the contract
        vm.broadcast(deployer);
        limitOrderManager = new LimitOrderManager(lbFactory, wnative);
    }
}
