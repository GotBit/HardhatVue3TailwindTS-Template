//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC1155Extended
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract ERC1155Extended is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER');
    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR');

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public idCounter = 1;

    mapping(uint256 => string) public uris;

    event Created(address who, uint256 id);
    event UpdatedTokenURI(uint256 indexed tokenId, string uri_);

    modifier exist(uint256 id) {
        require(id < idCounter, 'ERC1155Extended: id does not exist');
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC1155('') {
        name = name_;
        symbol = symbol_;
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev mints `amount` tokens `to` with `id` (only for `MINTER_ROLE`)
    /// @param to address of user for minting
    /// @param id uint id which be minted
    /// @param amount uint amounts of id
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public virtual exist(id) onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, '');
    }

    /// @dev mints `amounts` tokens `to` with `ids` (only for `MINTER_ROLE`)
    /// @param to address of user for minting
    /// @param ids uint[] ids which be minted
    /// @param amounts uint[] amounts of each id
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, '');
    }

    /// @dev creates new id of token
    /// @param uri_ uri of created token
    function create(string memory uri_)
        external
        virtual
        onlyRole(CREATOR_ROLE)
        returns (uint256 id)
    {
        emit Created(msg.sender, idCounter);
        id = idCounter;
        idCounter++;

        setTokenURI(id, uri_);
    }

    /// @dev sets token uri for id (only for `CREATOR_ROLE`)
    /// @param id id of token
    /// @param uri_ uri string of token
    function setTokenURI(uint256 id, string memory uri_)
        public
        exist(id)
        onlyRole(CREATOR_ROLE)
    {
        uris[id] = uri_;
        emit UpdatedTokenURI(id, uri_);
    }

    /// @dev grants minter role to user (only for `DEFAULT_ADMIN_ROLE`)
    /// @param user address of user
    function grantRoleMinter(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, user);
    }

    /// @dev revokes minter role from user (only for `DEFAULT_ADMIN_ROLE`)
    /// @param user address of user
    function revokeRoleMinter(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, user);
    }

    /// @dev grants creator role to user (only for `DEFAULT_ADMIN_ROLE`)
    /// @param user address of user
    function grantRoleCreator(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(CREATOR_ROLE, user);
    }

    /// @dev revokes creator role from user (only for `DEFAULT_ADMIN_ROLE`)
    /// @param user address of user
    function revokeRoleCreator(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(CREATOR_ROLE, user);
    }

    /// @dev returns uri for `id`
    /// @param id id of token
    /// @return uri_ uri string of token with `id`
    function uri(uint256 id) public view override exist(id) returns (string memory uri_) {
        return uris[id];
    }

    /// @dev returns info for specific token id and reverts when id does not exist
    /// @param id uint256 id of token
    /// @return uri_ uri string of token with `id`
    function infoBundleForToken(uint256 id)
        external
        view
        virtual
        exist(id)
        returns (string memory uri_)
    {
        return uri(id);
    }

    struct InfoUser {
        uint256 id;
        uint256 balance;
        string uri;
    }

    /// @dev returns info about `user`
    /// @param user address
    /// @return infoUser info about each token id
    function infoBundleForUser(address user)
        external
        view
        virtual
        returns (InfoUser[] memory infoUser)
    {
        InfoUser[] memory infoUser_ = new InfoUser[](idCounter - 1);
        for (uint256 i = 1; i < idCounter; i++) {
            infoUser_[i - 1] = InfoUser({
                id: i,
                balance: balanceOf(user, i),
                uri: uri(i)
            });
        }
        return infoUser_;
    }
}
