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

import { IController } from "../../interfaces/IController.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { IBatchValuer } from "../../interfaces/IBatchValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 * @author Kianite Limited
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // PriceOracle will always be resource ID 0 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 0;
    // SetValuer resource will always be resource ID 1 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 1;

    /* ============ Internal ============ */

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 0 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 1 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (IBatchValuer) {
        return IBatchValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}