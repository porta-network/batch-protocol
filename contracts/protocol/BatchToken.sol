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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IController } from "../interfaces/IController.sol";
import { IBatchToken } from "../interfaces/IBatchToken.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";


/**
 * @title BatchToken
 * @author Set Protocol
 * @author Kianite Limited
 *
 */
contract BatchToken is ERC20 {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for int256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event Invoked(address indexed _target, uint indexed _value, bytes _data, bytes _returnValue);
    event ManagerEdited(address _newManager, address _oldManager);
    event ComponentAdded(address indexed _component, string _ticker);
    event ComponentRemoved(address indexed _component, string _ticker);

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the BatchToken's manager
     */
    modifier onlyManager() {
        _validateOnlyManager();
        _;
    }

    /**
     * Throws if BatchToken is locked and called by any account other than the locker.
     */
    modifier whenLockedOnlyLocker() {
        _validateWhenLockedOnlyLocker();
        _;
    }

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    // The manager has the privelege to add modules, remove, and set a new manager
    address public manager;

    // A module that has locked other modules from privileged functionality, typically required
    // for multi-block module actions such as auctions
    address public locker;

    // List of initialized Modules; Modules extend the functionality of BatchTokens
    address[] public modules;

    // When locked, only the locker (a module) can call privileged functionality
    // Typically utilized if a module (e.g. Auction) needs multiple transactions to complete an action
    // without interruption
    bool public isLocked;

    // List of components
    address[] public components;

    // List of asset tickers
    string[] public componentTickers;

    // The max a token market can be when it enters the index
    int256 marketCapMax;

    // The min a token market can be when it enters the index
    int256 marketCapMin;

    // Bool to verify the max market cap before adding to index
    bool checkMaxCap = false;

    // Bool to verify the min market cap before adding to index
    bool checkMinCap = false;

    /* ============ Constructor ============ */

    /**
     * All parameter validations are on the BatchTokenCreator contract. Validations are performed already on the 
     * BatchTokenCreator. Initiates the positionMultiplier as 1e18 (no adjustments).
     *
     * @param _components             List of addresses of components for initial Positions
     * @param _componentTickers       List of strings of components tickers
     * @param _controller             Address of the controller
     * @param _manager                Address of the manager
     * @param _name                   Name of the BatchToken
     * @param _symbol                 Symbol of the BatchToken
     */
    constructor(
        address[] memory _components,
        address[] memory _componentTickers,
        IController _controller,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        public
        ERC20(_name, _symbol)
    {
        controller = _controller;
        manager = _manager;
        components = _components;
        componentTickers = _componentTickers;
    }

    /* ============ External Functions ============ */

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that allows a module to make an arbitrary function
     * call to any contract.
     *
     * @param _target                 Address of the smart contract to call
     * @param _value                  Quantity of Ether to provide the call (typically 0)
     * @param _data                   Encoded function selector and arguments
     * @return _returnValue           Bytes encoded return value
     */
    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    )
        external
        whenLockedOnlyLocker
        returns (bytes memory _returnValue)
    {
        _returnValue = _target.functionCallWithValue(_data, _value);

        emit Invoked(_target, _value, _data, _returnValue);

        return _returnValue;
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that adds a component to the components array.
     */
    function addComponent(address _component, string _ticker) external whenLockedOnlyLocker {
        components.push(_component);
        componentTickers.push(_ticker);

        emit ComponentAdded(_component, _ticker);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that removes a component from the components array.
     */
    function removeComponent(address _component, string _ticker) external whenLockedOnlyLocker {
        components = components.remove(_component);
        componentTickers = componentTickers.remove(_ticker);

        emit ComponentRemoved(_component, _ticker);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Increases the "account" balance by the "quantity".
     */
    function mint(address _account, uint256 _quantity) external whenLockedOnlyLocker {
        _mint(_account, _quantity);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Decreases the "account" balance by the "quantity".
     * _burn checks that the "account" already has the required "quantity".
     */
    function burn(address _account, uint256 _quantity) external whenLockedOnlyLocker {
        _burn(_account, _quantity);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. When a BatchToken is locked, only the locker can call privileged functions.
     */
    function lock() external  {
        require(!isLocked, "Must not be locked");
        locker = msg.sender;
        isLocked = true;
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Unlocks the BatchToken and clears the locker
     */
    function unlock() external  {
        require(isLocked, "Must be locked");
        require(locker == msg.sender, "Must be locker");
        delete locker;
        isLocked = false;
    }

    /**
     * MANAGER ONLY. Changes manager; We allow null addresses in case the manager wishes to wind down the BatchToken.
     */
    function setManager(address _manager) external onlyManager {
        require(!isLocked, "Only when unlocked");
        address oldManager = manager;
        manager = _manager;

        emit ManagerEdited(_manager, oldManager);
    }

    /* ============ External Getter Functions ============ */

    function getComponents() external view returns(address[] memory) {
        return components;
    }

    function isComponent(address _component) external view returns(bool) {
        return components.contains(_component);
    }

    receive() external payable {} // solium-disable-line quotes

    /* ============ Internal Functions ============ */

    /**
     * Due to reason error bloat, internal functions are used to reduce bytecode size
     *
     * Module must be initialized on the BatchToken and enabled by the controller
     */

    function _validateOnlyManager() internal view {
        require(msg.sender == manager, "Only manager can call");
    }

    function _validateWhenLockedOnlyLocker() internal view {
        if (isLocked) {
            require(msg.sender == locker, "When locked, only the locker can call");
        }
    }
}