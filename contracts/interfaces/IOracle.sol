/*
    Copyright 2021 Kianite Limited.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;


/**
 * @title IOracle
 * @author Kianite Limited
 *
 * Interface for operating with any external Oracle that returns uint256 or
 * an adapting contract that converts oracle output to uint256
 */
interface IOracle {
    /**
     * @return  Current price of asset represented in uint256
     */
    function getValue() external view returns (uint256);
}