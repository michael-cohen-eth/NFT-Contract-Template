// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "ERC721Common.sol";

/**
 * @title MinterMixin
 * MinterMixin - Mixin that introduces a max supply, a Minter role, and an auto-incrementing tokenId
 */
abstract contract MinterMixin is ERC721Common {
    using Counters for Counters.Counter;

    // Used for access management
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Maximium amount allowed to mint
    uint256 private _maxSupply;

    // The price to purchase
    uint256 private _price;

    /*
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 
    Counters.Counter private _nextTokenId;

    constructor(uint256 maxSupply, uint256 price) {
        _grantRole(MINTER_ROLE, msg.sender);
        
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _maxSupply = maxSupply;
        _price = price;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mint(address _to) public virtual payable onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 currentTokenId = _nextTokenId.current();
        require(currentTokenId < _maxSupply, "Max supply reached");
        require(msg.value == _price, "Transaction value did not equal the mint price");

        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
        return currentTokenId;
    }

    /**
     * @dev Returns the total tokens minted so far.
     * 1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /**
     * @dev Grants the address provided the MINTER role
     * @param minter address of the third-party operator
     */
    function allowAddressForMinting(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(!hasRole(MINTER_ROLE, minter), "Provided address already allowed to mint");
      _grantRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Revokes the OPERATOR role from the address
     * @param minter address of the third-party operator
     */
    function removeAddressFromMinting(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(hasRole(MINTER_ROLE, minter), "Provided address not allowed to mint already");
      _revokeRole(MINTER_ROLE, minter);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Common)
        virtual
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
