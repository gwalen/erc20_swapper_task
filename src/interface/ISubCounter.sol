// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface ISubCounter {

    enum Status { GOOD, BAD }

    struct IncrementorInfo {
        uint256 blockTimestamp;
        address incrementor;
        Status status;
    }

    function addIncrementor(address account) external;
    function incrementorsLen() external view returns (uint256);
    function setParent(address new_parent) external;
    function parent() external view returns(address);
    function addIncrementorInfo(address incrementor, Status status) external;
    function readLastIncrementorInfo() external view returns (IncrementorInfo memory);
    
}