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

/**
 * @title StringArrayUtils
 * @author Set Protocol
 * @author Kianite Limited
 *
 * Utility functions to handle String Arrays
 */
library StringArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(string[] memory A, string memory a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (compareStringsbyBytes(A[i], a)) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(string[] memory A, string memory a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(string[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            string memory current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (compareStringsbyBytes(current, A[j])) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The string to remove     
     * @return Returns the array with the object removed.
     */
    function remove(string[] memory A, string memory a)
        internal
        pure
        returns (string[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("String not in array.");
        } else {
            (string[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(string[] memory A, uint256 index)
        internal
        pure
        returns (string[] memory, string memory)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        string[] memory newStrings = new string[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newStrings[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newStrings[j - 1] = A[j];
        }
        return (newStrings, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(string[] memory A, string[] memory B) internal pure returns (string[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        string[] memory newStrings = new string[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newStrings[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newStrings[aLength + j] = B[j];
        }
        return newStrings;
    }

    function compareStringsbyBytes(string memory a, string memory b) public pure returns(bool){
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
}