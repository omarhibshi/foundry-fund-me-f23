// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

//The purpose of this contract:
// 1. Deploy mocks when we are on a local anvil chain.
// 2. Keep track of contract address across different chains.
//    - Sepolia ETH/USD
//    - Mainnet ETH/USD}

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getorCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // Network configurations examples:
        // - Price feed address on Sepolia
        // - vrf coordinator address on Sepolia
        // - gas price oracle address on Sepolia

        NetworkConfig memory SepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306}); //  "new" is not used because it is a typecasting
        return SepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419}); //  "new" is not used because it is a typecasting
        return ethConfig;
    }

    function getorCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // first check if a mock is already deployed, in this case priceFeed will be set to anything other than 0x0 (address(0)
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        //
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);
        address mockAddress = address(mock);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: mockAddress}); //  "new" is not used because it is a typecasting
        return anvilConfig;
    }
}
