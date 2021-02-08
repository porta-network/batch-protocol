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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IBatchToken } from "../interfaces/IBatchToken.sol";
import { IOracle } from "../interfaces/IOracle.sol";


import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";
import { StringArrayUtils } from "../lib/StringArrayUtils.sol";


/**
 * @title BatchToken
 * @author Kianite Limited
 *
 */
contract BatchToken is ERC20, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for int256;
    using Address for address;
    using AddressArrayUtils for address[];
    using StringArrayUtils for string[];

    
    /* ============ Events ============ */

    event ManagerEdited(address _newManager, address _oldManager);
    event AssetSwaped(string indexed _tickerOld, string indexed _tickerNew);
    event UpdateTargetValue(uint256 _batchTargetValue);
    event UpdateTradingValue(uint256 _batchTradingValue);
    event UpdateMaxAssets(bool _result);
    event TargetOracleUpdated(address _targetOracle);
    event TradingOracleUpdated(address _tradingOracle);

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the BatchToken's manager
     */
    modifier onlyManager() {
        _validateOnlyManager();
        _;
    }

    /* ============ State Variables ============ */


    // The manager has the privelege to make changes to the index composition, and set a new manager
    address public manager;

    // List of asset tickers
    string[] public assets;

    // The current value of the assets in the batch index
    uint256 batchTargetValue = 0;

    // The current value that the batch is trading at
    uint256 batchTradingValue = 0;

    IOracle public TargetPriceOracle;
    IOracle public TradingPriceOracle;


  /* ============ Constructor ============ */

  /**
    * All parameter validations are on the BatchTokenCreator contract. Validations are performed already on the 
    * BatchTokenCreator. Initiates the positionMultiplier as 1e18 (no adjustments).
    *
    * @param _assets       List of strings of components tickers
    * @param _manager                Manager of the BatchToken
    * @param _name                   Name of the BatchToken
    * @param _symbol                 Symbol of the BatchToken
    */
  constructor(
      string[] memory _assets,
      address _manager,
      IOracle _oracleTarget,
      IOracle _oracleTrading,
      string memory _name,
      string memory _symbol
  )
      public
      ERC20(_name, _symbol)
  {
      TargetPriceOracle = _oracleTarget;
      TradingPriceOracle =  _oracleTrading;
      manager = _manager;
      transferOwnership(_manager);
      assets = _assets;
  }

  /* ============ External Functions ============ */

  // 
  function getBatchTargetValue() public returns(uint256) {
    batchTargetValue = TargetPriceOracle.getValue();
    emit UpdateTargetValue(batchTargetValue);
    return batchTargetValue;
  }
  
  function getBatchTradingValue() public returns(uint256) {
    batchTradingValue = TradingPriceOracle.getValue();
    emit UpdateTradingValue(batchTradingValue);
    return batchTradingValue;
  }
  
  /**
  * Low level function that removes an asset from the asset array and adds a new one.
  */
  function swapAsset(string memory _tickerToAdd, string memory _tickerToRemove) external onlyManager {
    require(assets.contains(_tickerToRemove), "This asset is  not in the list");
    require(!assets.contains(_tickerToAdd), "This asset is  already in the list");
    assets = assets.remove(_tickerToRemove);
    assets.push(_tickerToAdd);

    emit AssetSwaped(_tickerToAdd, _tickerToRemove);
  }


  /**
  * Adjust the total supply of tokens in order to make batch token price reach index price.
  */
  function adjustSupply() external onlyManager {
      address contractAddress = address(this);
      uint256 totalSupply = this.totalSupply();
      // Add an extra 18 decemals to the total supply to make it in line with the batchTradingValue
      // Which is already multiplyed by 18 decemals
      uint256 totalSupplyFixed = totalSupply * 10 ** 18;

      // Calculate the total market value of all the tokens in existence 
      uint256 notionalValueFixed = SafeMath.mul(batchTradingValue, totalSupplyFixed);

      // This is the price adjusted supply multiplied by 18 decemals.
      // Devide the value off all the tokens in existence by the target price for the token
      // In order to get the supply we would have if adjusted for price
      uint256 priceAdjustedSupplyFixed = SafeMath.div(notionalValueFixed, batchTargetValue);

      // This is devided to get back to an 18 decamal value
      uint256 priceAdjustedSupply = priceAdjustedSupplyFixed / (10 ** 18);

      // Get the reserve token balance
      uint256 reserveBalance = this.balanceOf(contractAddress);

      uint256 circulatingSupply = SafeMath.sub(totalSupply, reserveBalance);

      uint256 adjustedReserveBalance = SafeMath.sub(priceAdjustedSupply, circulatingSupply);

      // If the price adjusted supply is 0 that means that price 
      // is being tracked acuratly and there is no need to adjust the supply
      require(adjustedReserveBalance == reserveBalance, "No supply adjustment needed");

      // The adjusted reserve balance minus the current reserve balance will give 
      uint256 reserveCorrection = SafeMath.sub(adjustedReserveBalance, reserveBalance);

      if(reserveCorrection > 0) {
        // Mint new reserve tokens to balance price
        _mint(contractAddress, reserveCorrection);
      } else {
        // cast reserveCorrection to a positive number and burn the reserve tokens
        int256 positiveReserveCorection = int256(reserveCorrection);
        _burn(contractAddress, uint256(positiveReserveCorection));
      }
  }


  /**
  * Increases the "account" balance by the "quantity".
  */
  function mint(address _account, uint256 _quantity) external onlyOwner {
      _mint(_account, _quantity);
      _mint(address(this), _quantity * 9999999);
  }

  /**
  *  Decreases the "account" balance by the "quantity".
  * _burn checks that the "account" already has the required "quantity".
  */
  function burn(address _account, uint256 _quantity) external onlyOwner {
      _burn(_account, _quantity);
      _burn(address(this), _quantity * 9999999);
  }

  /**
    * Update Trarget price oracle address
    */
  function updateTargetOracle(IOracle _targetPriceOracle) external onlyOwner {
      TargetPriceOracle = _targetPriceOracle;
      emit TargetOracleUpdated(TargetPriceOracle);
  }
  
  /**
  * Update Trading price oracle address
  */
  function updateTradingOracle(IOracle _tradingPriceOracle) external onlyOwner {
      TradingPriceOracle = _tradingPriceOracle;
      emit TradingOracleUpdated(TradingPriceOracle);
  }
  

  /* ============ Internal Functions ============ */

  /**
    * Due to reason error bloat, internal functions are used to reduce bytecode size
    *
    * Module must be initialized on the BatchToken and enabled by the controller
    */

  function _validateOnlyManager() internal view {
      require(msg.sender == manager, "Only manager can call");
  }

  function _beforeTokenTransfer( address from, address to, uint256 amount) internal virtual override() {
    super._beforeTokenTransfer(from, to, amount);

    if(from == address(this) && to != address(0)) {
      revert("Reserve funds can not be moved");
    }
    
    if(to == address(this) && from != address(0)) {
      revert("Reserve funds can not be moved");
    }
  }
}