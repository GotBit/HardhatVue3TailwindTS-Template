//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155DataStorage
 * @author gotbit
 */

import '../ERC1155Extended.sol';

abstract contract ERC1155DataStorage is ERC1155Extended {
    struct Data {
        string name_;
        uint256 power;
        string rarity;
    }

    mapping(uint256 => Data) public datas;
    event UpdatedTokenData(uint256 indexed id, Data data_);

    /// @dev creates new id of token
    function create(string memory uri_, Data memory data_)
        external
        onlyRole(CREATOR_ROLE)
        returns (uint256 id)
    {
        emit Created(msg.sender, idCounter);
        id = idCounter;
        idCounter++;

        setTokenURI(id, uri_);
        setTokenData(id, data_);
    }

    function setTokenData(uint256 id, Data memory data_)
        public
        exist(id)
        onlyRole(CREATOR_ROLE)
    {
        datas[id] = data_;
        emit UpdatedTokenData(id, data_);
    }

    function data(uint256 id) external view exist(id) returns (Data memory data_) {
        return datas[id];
    }

    function infoBundleForTokenData(uint256 id)
        external
        view
        returns (string memory uri_, Data memory data_)
    {
        return (uri(id), datas[id]);
    }

    struct InfoUserData {
        uint256 id;
        uint256 balance;
        string uri;
        Data data;
    }

    function infoBundleForUserData(address user)
        external
        view
        returns (InfoUserData[] memory infoUserData)
    {
        InfoUserData[] memory infoUserData_ = new InfoUserData[](idCounter - 1);
        for (uint256 id = 1; id < idCounter; id++) {
            infoUserData_[id - 1] = InfoUserData({
                id: id,
                balance: balanceOf(user, id),
                uri: uri(id),
                data: datas[id]
            });
        }
        return infoUserData_;
    }
}
