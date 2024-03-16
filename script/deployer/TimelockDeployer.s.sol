// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @dev Timelock contract to make sure proxy in not upgraded without a public proposal
 *      amd time to leave the contract if malicious changes are introduced 
 */
contract TimelockDeployer {
    uint256 constant TIMELOCK_MIN_DELAY = 172800; // 48h
    address timelockAdmin;
    address[] timelockProposers;
    address[] timelockExecutors;

    TimelockController public timelock;

    function deployTimelock(address owner) internal {
        timelockProposers = [owner];
        timelockExecutors = [owner];
        timelockAdmin = owner;
        timelock = new TimelockController(TIMELOCK_MIN_DELAY, timelockProposers, timelockExecutors, timelockAdmin);
    }
}