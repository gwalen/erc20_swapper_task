// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./interface/ISubCounter.sol";

contract Counter {
    address public admin;
    uint256 public number;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public userCounter;
    
    ISubCounter subCounter;

    // error OnlAdminCanWhitelist();
    error OnlyWhitelisted(address account);

    constructor(address _admin) {
        admin = _admin;
        number = 0;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyWhitelisted {
        // require(whitelist[msg.sender], "Only whitelisted");
        if (!whitelist[msg.sender]) {
            revert OnlyWhitelisted(msg.sender);
        }
        _;
    }

    function counterValue() external view returns (uint256) {
        return number;
    }

    function userCounterValue(address user) external view returns (uint256) {
        return userCounter[user];
    }

    function increment() external onlyWhitelisted {
        userCounter[msg.sender] += 1;
        number++;
    }

    function addIncrementor(address incrementor) external {
        require(address(subCounter) != address(0), "subCounter not set");
        subCounter.addIncrementor(incrementor);
    }

    function addUserToWhitelist(address newUser) external onlyAdmin {
        whitelist[newUser] = true;
    }

    function removeUserFromWhiteList(address newUser) external onlyAdmin {
        delete whitelist[newUser]; // will set the value to default (false in this case)
    }

    function setSubContract(address account) external onlyAdmin {
        subCounter = ISubCounter(account);
    }
}
