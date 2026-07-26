// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Script} from "forge-std/Script.sol";
import {TokenMarketplace} from "../src/TokenMarketplace.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";

contract TokenMarketplaceScript is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config =
            block.chainid == helperConfig.LOCAL_CHAIN_ID() ? helperConfig.setUpAnvilConfig() : helperConfig.getConfig();

        vm.startBroadcast();
        TokenMarketplace tokenMarketplace = new TokenMarketplace(config.slvToken, config.initialOwner);
        vm.stopBroadcast();
        console2.log("TokenMarketplace deployed at:", address(tokenMarketplace));
    }
}
