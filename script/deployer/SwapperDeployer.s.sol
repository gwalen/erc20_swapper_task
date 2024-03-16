// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";
import {Swapper} from "../../src/Swapper.sol";

/**
 * @notice Swapper deployer script contract. 
 *         It has has separate deployer for proxy and implementation so that we can use it for proxy upgrades in future.  
 */
// contract SwapperDeployer is Script {
contract SwapperDeployer  {
    Swapper public swapperImpl;
    Swapper public swapperProxy; 

    function deployImplementation() public {
        swapperImpl = new Swapper();
    }

    function deployProxy(address owner, address uniV3Router, address WETH) public {
        require(address(swapperImpl) != address(0), "Swapper implementation not deployed");
    
        ERC1967Proxy proxy = new ERC1967Proxy(address(swapperImpl), "");
        // TODO: check without payable - should fail cos we are sending ether to our function
        swapperProxy = Swapper(payable(proxy));
        swapperProxy.initialize(owner, uniV3Router, WETH);
    }
}