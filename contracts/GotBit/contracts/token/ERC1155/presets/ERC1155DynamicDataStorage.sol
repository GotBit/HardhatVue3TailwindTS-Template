//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155DynamicDataStorage
 * @author gotbit
 */

import '../extensions/ERC1155DataStorage.sol';
import '../extensions/ERC1155Dynamic.sol';

contract ERC1155DynamicDataStorage is
    ERC1155Extended,
    ERC1155DataStorage,
    ERC1155Dynamic
{
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC1155Extended(name_, symbol_, owner_) {
        name = name_;
        symbol = symbol_;
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    /// @dev creates new id of token
    /// @param uri_ uri of created token
    /// @param data_ data of created token
    /// @param dynamicProps_ dynamic propirites of created token
    function create(
        string memory uri_,
        Data memory data_,
        DynamicProps memory dynamicProps_
    ) external onlyRole(CREATOR_ROLE) returns (uint256 id) {
        emit Created(msg.sender, idCounter);
        id = idCounter;
        idCounter++;

        setTokenURI(id, uri_);
        setTokenData(id, data_);
        setTokenDynamic(id, dynamicProps_);
    }

    /// @dev returns info for specific token id and reverts when id does not exist
    /// @param id uint256 id of token
    /// @return uri_ uri string of token with `id`
    /// @return data_ data structure associated with token `id`
    /// @return dynamicProps_ dynamic properties associated with token `id`
    function infoBundleForTokenExtra(uint256 id)
        external
        view
        returns (
            string memory uri_,
            Data memory data_,
            DynamicProps memory dynamicProps_
        )
    {
        return (uri(id), datas[id], dynamicProps[id]);
    }

    struct InfoUserExtra {
        uint256 id;
        uint256 balance;
        string uri;
        ERC1155DataStorage.Data data;
        ERC1155Dynamic.Dynamic[] dynamics;
    }

    /// @dev returns info about `user`
    /// @param user address
    /// @return infoUserExtra info about each token id
    function infoBundleForUserExtra(address user)
        external
        view
        returns (InfoUserExtra[] memory infoUserExtra)
    {
        InfoUserExtra[] memory infoUserExtra_ = new InfoUserExtra[](idCounter - 1);
        for (uint256 id = 1; id < idCounter; id++) {
            DynamicProps memory dynamicProps_ = dynamicProps[id];

            Dynamic[] memory dynamics = new Dynamic[](
                dynamicProps_.max - dynamicProps_.min + 1
            );
            for (uint256 value = dynamicProps_.min; value <= dynamicProps_.max; value++)
                dynamics[value - dynamicProps_.min] = Dynamic(
                    dynamicProps_.name,
                    value,
                    dynamicBalances[user][id][value]
                );

            infoUserExtra_[id - 1] = InfoUserExtra({
                id: id,
                balance: balanceOf(user, id),
                uri: uri(id),
                data: datas[id],
                dynamics: dynamics
            });
        }

        return infoUserExtra_;
    }
}
