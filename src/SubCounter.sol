// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISubCounter} from "./interface/ISubCounter.sol";


contract SubCounter is ISubCounter {
    address[] public incrementors;
    address public deployer;
    address private _parent;
    IncrementorInfo[] public incrementorsInfo;

    error OnlyDeployerError();
    error OnlyOwnerError();

    modifier OnlyDeployer() {
        if (msg.sender != deployer) {
            revert OnlyDeployerError();
        }
        _;
    }

    modifier OnlyParent() {
        if (msg.sender != _parent) {
            revert OnlyOwnerError();
        }
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setParent(address new_parent) external OnlyDeployer {
        _parent = new_parent;
    }

    function addIncrementor(address account) external OnlyParent {
        incrementors.push(account);
    }
 
    function incrementorsLen() external view returns (uint256) {
        return incrementors.length;
    }

    function addIncrementorInfo(address incrementor, Status status) external {
        IncrementorInfo memory newInfo = IncrementorInfo(
            block.timestamp,
            incrementor,
            status
        );
        incrementorsInfo.push(newInfo);
    }

    function readLastIncrementorInfo() external view returns (IncrementorInfo memory) {
        // IncrementorInfo memory ret = incrementorsInfo[incrementorsInfo.length - 1];
        return incrementorsInfo[incrementorsInfo.length - 1];
    }

    function unusableTestOfMemoryArray() external pure returns (uint256) {
        uint256[] memory arr = new uint256[](10);
        arr[0] = 1;
        arr[1] = 2;
        arr[3] = arr[1] + arr[2];
        return arr[3];
    }

    function parent() external view returns (address) {
        return _parent;
    }
}




