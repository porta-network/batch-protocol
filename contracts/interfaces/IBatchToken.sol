/*
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBatchToken
 * @author Kianite Limited
 *
 * Interface for operating with BatchTokens.
 */
interface IBatchToken is IERC20 {

    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    
    function getComponents() external view returns(address[] memory);
    function isComponent(address _component) external view returns(bool);
  
    function isLocked() external view returns (bool);
}