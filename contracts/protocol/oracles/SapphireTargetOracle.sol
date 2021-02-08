// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SapphireTargetOracle is ChainlinkClient, Ownable {

    /* ============ Events ============ */
    event OracleUpdated(address _oracle);
    event JobIdUpdated(bytes32 _jobId);
    event LinkWithdrawn(uint256 _balance);
    event feeUpdated(uint _fee);
  
    /* ============ State Variables ============ */
    uint256 public value;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    /**
     * Chainlink - 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * Chainlink - 29fa9aa13bf1468788b7cc4a500a45b8
     * Fee: 0.1 * 10 ** 18; // 0.1 LINK
     */
    constructor(address _oracle, bytes32 _jobId, uint _fee) public {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestValue(string _ticker) public onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", "https://api.exchangeratesapi.io/latest");
        
        // Set the path to find the desired data in the API response
        request.add("path", "rates.USD");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _value) public recordChainlinkFulfillment(_requestId) {
        value = _value;
    }

    /**
     * Returns the last value set by the oracle call
     */
    function getValue() external view returns(uint256) {
        return value;
    }
    
    /**
     * Withdraw LINK from this contract
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(chainlinkTokenAddress());
        uint256 balance = linkToken.balanceOf(address(this));
        require(linkToken.transfer(msg.sender, balance), "Unable to transfer");
        emit LinkWithdrawn(balance);
    }

    /**
     * Update the address of the oracle being used
     */
    function updateOracleAddress(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }
    
    /**
     * Update the jobId of the oracle being used
     */
    function updateJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
        emit JobIdUpdated(jobId);
    }

    /**
     * Update the fee to be paid to oracle provider
     */
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit feeUpdated(fee);
    }
}
