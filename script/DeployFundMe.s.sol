//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FundMe} from "../src/FundMe.sol";


contract DeployFundMe is Script { // if we do not declare is Script then we will not be able to use vm.startBroadcast()
    function run() external returns (FundMe) {
        //anything before startBroadcast will not be sent as real transaction, it will simulate in simulated environment
        HelperConfig helperConfig = new HelperConfig();
        (address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();
        // after starBroadcast its gonna be real transaction
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}