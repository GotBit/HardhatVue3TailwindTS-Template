// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFT
 * @author gotbit
 */

import './GotBit/contracts/token/ERC1155/presets/ERC1155DynamicDataStorage.sol';

contract NFT is ERC1155DynamicDataStorage {
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC1155DynamicDataStorage(name_, symbol_, owner_) {}
}
