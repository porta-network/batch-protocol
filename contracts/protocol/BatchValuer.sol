/*
    Copyright 2020 Set Labs Inc.
    Copyright 2021 Kianite Limited.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IController } from "../interfaces/IController.sol";
import { IBatchToken } from "../interfaces/IBatchToken.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./lib/ResourceIdentifier.sol";


/**
 * @title BatchValuer
 * @author Set Protocol
 * @author Kianite Limited
 *
 * Contract that returns the valuation of BatchTokens using price oracle data used in contracts
 * that are external to the system.
 *
 * Note: Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract BatchValuer {
    using PreciseUnitMath for int256;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    
    /* ============ State Variables ============ */

    // Instance of the Controller contract
    IController public controller;

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * Gets the valuation of a BatchToken using data from the price oracle. Reverts
     * if no price exists for a component in the BatchToken.
     * 
     * Note: There is a risk that the valuation is off if airdrops aren't retrieved or
     * debt builds up via interest and its not reflected in the position
     *
     * @param _batchToken      BatchToken instance to get valuation
     * @param _quoteAsset      Address of token to quote valuation in
     *
     * @return                 BatchToken valuation in terms of quote asset in precise units 1e18
     */
    function calculateBatchTokenValuation(IBatchToken _batchToken, address _quoteAsset) external view returns (uint256) {
        IPriceOracle priceOracle = controller.getPriceOracle();
        address masterQuoteAsset = priceOracle.masterQuoteAsset();
        address[] memory components = _batchToken.getComponents();
        int256 valuation;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            // Get component price from price oracle. If price does not exist, revert.
            uint256 componentPrice = priceOracle.getPrice(component, masterQuoteAsset);

            // Calculate valuation of the component. Debt positions are effectively subtracted
            valuation = componentPrice.toInt256().add(valuation);
        }

        if (masterQuoteAsset != _quoteAsset) {
            uint256 quoteToMaster = priceOracle.getPrice(_quoteAsset, masterQuoteAsset);
            valuation = valuation.preciseDiv(quoteToMaster.toInt256());
        }

        return valuation.toUint256();
    }
}
