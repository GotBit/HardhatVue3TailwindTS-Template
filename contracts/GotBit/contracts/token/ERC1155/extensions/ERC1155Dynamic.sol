//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155Dynamic
 * @author gotbit
 */

import '../ERC1155Extended.sol';

abstract contract ERC1155Dynamic is ERC1155Extended {
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER');

    struct DynamicProps {
        string name;
        uint256 min;
        uint256 max;
    }

    mapping(uint256 => DynamicProps) public dynamicProps;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public dynamicBalances;

    event UpdateTokenDynamic(uint256 id, DynamicProps dynamicProps_);
    event Upgrade(address user, uint256 id, uint256 from, uint256 to, uint256 amount);

    function create(string memory uri_, DynamicProps memory dynamicProps_)
        external
        onlyRole(CREATOR_ROLE)
        returns (uint256 id)
    {
        emit Created(msg.sender, idCounter);
        id = idCounter;
        idCounter++;

        setTokenURI(id, uri_);
        setTokenDynamic(id, dynamicProps_);
    }

    function setTokenDynamic(uint256 id, DynamicProps memory dynamicProps_)
        public
        exist(id)
        onlyRole(CREATOR_ROLE)
    {
        require(dynamicProps_.max >= dynamicProps_.min, '`max` cant be less than `min`');
        dynamicProps[id] = dynamicProps_;
        emit UpdateTokenDynamic(id, dynamicProps_);
    }

    /// @dev grants updgrader role to user (only for `DEFAULT_ADMIN_ROLE`)
    /// @param user address of user
    function grantRoleUpgrader(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(UPGRADER_ROLE, user);
    }

    /// @dev revokes upgrader role from user (only for `DEFAULT_ADMIN_ROLE`)
    /// @param user address of user
    function revokeRoleUpgrader(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(UPGRADER_ROLE, user);
    }

    function upgrade(
        address user,
        uint256 id,
        uint256 from,
        uint256 to,
        uint256 amount
    ) external onlyRole(UPGRADER_ROLE) {
        require(
            dynamicBalances[user][id][from] >= amount,
            'Not enough tokens with corresponding value "from"'
        );
        require(
            from >= dynamicProps[id].min && from < dynamicProps[id].max,
            'Wrond "from" value'
        );
        require(
            to <= dynamicProps[id].max && to > dynamicProps[id].min,
            'Wrond "to" value'
        );

        dynamicBalances[user][id][from] -= amount;
        dynamicBalances[user][id][to] += amount;

        emit Upgrade(user, id, from, to, amount);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        uint256 init
    ) external exist(id) onlyRole(MINTER_ROLE) {
        mint(to, id, amount);
        require(
            init >= dynamicProps[id].min && init < dynamicProps[id].max,
            'Wrond "init" value'
        );
        dynamicBalances[to][id][init] += amount;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory inits
    ) external onlyRole(MINTER_ROLE) {
        mintBatch(to, ids, amounts);
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i++) {
            dynamicBalances[to][ids[i]][inits[i]] += amounts[i];
        }
    }

    function infoBundleForTokenDynamic(uint256 id)
        external
        view
        returns (string memory uri_, DynamicProps memory dynamicProps_)
    {
        return (uri(id), dynamicProps[id]);
    }

    struct Dynamic {
        string name;
        uint256 value;
        uint256 balance;
    }

    struct InfoUserDynamic {
        uint256 id;
        uint256 balance;
        string uri;
        Dynamic[] dynamics;
    }

    function infoBundleForUserDynamic(address user)
        external
        view
        returns (InfoUserDynamic[] memory infoUserDynamic)
    {
        InfoUserDynamic[] memory infoUserDynamic_ = new InfoUserDynamic[](idCounter - 1);
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

            infoUserDynamic_[id - 1] = InfoUserDynamic({
                id: id,
                balance: balanceOf(user, id),
                uri: uri(id),
                dynamics: dynamics
            });
        }
        return infoUserDynamic_;
    }
}
