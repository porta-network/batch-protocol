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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IBatchToken } from "../../interfaces/IBatchToken.sol";


/**
 * @title Invoke
 * @author Set Protocol
 * @author Kianite Limited
 *
 * A collection of common utility functions for interacting with the BatchToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the BatchToken to set approvals of the ERC20 token to a spender.
     *
     * @param _batchToken        BatchToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the BatchToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        IBatchToken _batchToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _batchToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the BatchToken to transfer the ERC20 token to a recipient.
     *
     * @param _batchToken        BatchToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        IBatchToken _batchToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _batchToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the BatchToken to transfer the ERC20 token to a recipient.
     * The new BatchToken balance must equal the existing balance less the quantity transferred
     *
     * @param _batchToken        BatchToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        IBatchToken _batchToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the BatchToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_batchToken));

            Invoke.invokeTransfer(_batchToken, _token, _to, _quantity);

            // Get new balance of transferred token for BatchToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_batchToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the BatchToken to unwrap the passed quantity of WETH
     *
     * @param _batchToken        BatchToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(IBatchToken _batchToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _batchToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the BatchToken to wrap the passed quantity of ETH
     *
     * @param _batchToken        BatchToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(IBatchToken _batchToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _batchToken.invoke(_weth, _quantity, callData);
    }
}