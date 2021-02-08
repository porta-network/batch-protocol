// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity ^0.6.0;

import { DOSOnChainSDK } from "../DOSNetwork/DOSOnChainSDK.sol";
import "../DOSNetwork/lib/utils.sol";

contract SapphireDOSOracle is DOSOnChainSDK {
    using utils for *;

    /* ============ Events ============ */
    event valueRetrieved(uint _value);
    event DOSWithdrawn();
  
    /* ============ State Variables ============ */
    uint256 public value;
    mapping(uint => bool) private _valid_queries;
    
    constructor() public {
        // @dev: setup and then transfer DOS tokens into deployed contract
        // as oracle fees.
        // Unused fees can be reclaimed by calling DOSRefund() in the SDK.
        super.DOSSetup();
    }

    function CoinbaseEthPriceFeed() public {
      // Returns a unique queryId that caller caches for future verification
      uint queryId = DOSQuery(30, "https://api.coinbase.com/v2/prices/ETH-USD/spot", "$.data.amount");
      _valid_queries[queryId] = true;
    }


    function __callback__(uint queryId, bytes calldata result) override external auth {
        // Check whether @queryId corresponds to a previous cached one
        require(_valid_queries[queryId], "Unmatched response");

        // Deal with result
        string memory price_str = string(result);
        uint numberResult = price_str.str2Uint();
        value = numberResult * 10 ** 18;
        
        delete _valid_queries[queryId];

        emit valueRetrieved(value);
    }


    /**
     * Returns the last value set by the oracle call
     */
    function getValue() external view returns(uint256) {
        return value;
    }

    /**
     * Withdraw DOS from this contract
     */
    function withdrawDOS() external onlyOwner {
        DOSRefund();
        emit DOSWithdrawn();
    }
}