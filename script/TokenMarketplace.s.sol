// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.34;

import {Script} from "forge-std/Script.sol";
import {TokenMarketplace} from "../src/TokenMarketplace.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console2} from "forge-std/console2.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TokenMarketplaceScript is Script {
    uint256 private constant INITIAL_MARKETPLACE_TOKENS = 1_000;
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config =
            block.chainid == helperConfig.LOCAL_CHAIN_ID() ? helperConfig.setUpAnvilConfig() : helperConfig.getConfig();

        vm.startBroadcast();
        TokenMarketplace tokenMarketplace = new TokenMarketplace(config.slvToken, config.initialOwner);
        if (block.chainid == helperConfig.LOCAL_CHAIN_ID()) {
            ERC20Mock(config.slvToken).mint(address(tokenMarketplace), INITIAL_MARKETPLACE_TOKENS);
        }
        vm.stopBroadcast();
        console2.log("TokenMarketplace deployed at:", address(tokenMarketplace));
    }
}
