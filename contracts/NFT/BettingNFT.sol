// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../_ERCs/ERC721.sol";
import "../_ERCs/IERC20.sol";
import "./AccessControls.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Betting  NFT
 * @dev Issues ERC-721 tokens 
 */
contract BettingNFT is ERC721("Betting NFT", "MTN") {

    using SafeMath for uint256;

    // @notice event emitted upon construction of this contract, used to bootstrap external indexers
    event BettingNFTContractDeployed();

  
    // @notice event emitted when a tokens primary sale occurs
    event TokenPrimarySalePriceSet(
        uint256 indexed _tokenId,
        uint256 _salePrice
    );

    // @notice event emitted when token is minted
    event BettingNFTMinted(
        uint256 _tokenId,
        address _creator,
        address _owner,
        string _edition
    );

    event BettingResulted(
        address winner,
        uint256 cryptprice,
        uint256 awardprice
    );

  
    AccessControls public accessControls;

    /// @dev current max tokenId
    uint256 public tokenIdPointer = 1000;

    /// @dev TokenID -> Primary Ether Sale Price in Wei
    mapping(uint256 => uint256) public primarySalePrice;

    /// @dev award price in eth
    uint256 public awardPrice = 1;
    
    /// @dev TokenID -> bucketprice
    mapping(uint256 => uint256) public bucketpriceBytoken;

    /// @dev bucketprice -> TokenId
    mapping(uint256 => uint256) public tokenBybucketprice;

    /**
     @notice Constructor
     @param _accessControls Address of the BettingNFT access control contract
     */
    constructor(AccessControls _accessControls) public {
        accessControls = _accessControls;
        emit BettingNFTContractDeployed();
    }

    /**
     @notice Mints a BettingNFT AND when minting to a contract checks if the beneficiary is a 721 compatible
     @dev Only senders with either the admin or mintor role can invoke this method
     @param _beneficiary Recipient of the NFT
     @param _beginprice begin price of token bucket
     @return uint256 The token ID of the token that was minted
     */
    function mint(address _beneficiary, uint256 _beginprice) external returns (uint256) {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "BettingNFT.mint: Sender must have the admin or smart contract role"
        );
        require(
            _beginprice.mod(1000) == 0 && _beginprice >= 0,
            "Bucket range should be mathcked"
        );
        

        tokenIdPointer = tokenIdPointer.add(1);
        uint256 tokenId = tokenIdPointer;

        // Mint token and set token URI
        _safeMint(_beneficiary, tokenId);
        bucketpriceBytoken[tokenId] = _beginprice;
        // _setTokenURI(tokenId, _beginprice);


        emit BettingNFTMinted(tokenId, _msgSender(), _beneficiary, "1 of 1");

        return tokenId;
    }

    /**
     @notice Burns a BettingNFT
     @dev Only the owner or an approved sender can call this method
     @param _tokenId the token ID to burn
     */
    function burn(uint256 _tokenId) external {
        address operator = _msgSender();
        require(
            ownerOf(_tokenId) == operator || isApproved(_tokenId, operator),
            "BettingNFT.burn: Only garment owner or approved"
        );
        // Destroy token mappings
        _burn(_tokenId);

        delete primarySalePrice[_tokenId];
    }

    /**
     @notice Transfer a BettingNFT
     @dev Only the owner or an approved sender can call this method
     @param to Recipient of the NFT
     @param tokenId the token ID to transfer
     @param amount price of token in Eth
     */
    function transfer(address to, uint256 tokenId, uint256 amount) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        safeTransferFrom(_msgSender(), to, tokenId);
        (bool winnerTransferSuccess,) = _msgSender().call{value : amount}("");
        require(winnerTransferSuccess, "Betting.transfer: Failed to send money");
    }

    /**
     @notice Results a finished betting
     @dev Only admin or smart contract
     @param cryptprice the crpto currecny price when betting is finished
     */
    function resultAuction(uint256 cryptprice) external  payable{
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "Sender must be admin or smart contract"
        );
        uint256 beginprice = cryptprice.sub(cryptprice.mod(1000));
        uint256 tokenId = tokenBybucketprice[beginprice];
        require(tokenId != 0, "Bucket should be owned");
        address _winner = ownerOf(tokenId);
        require(_winner != address(0), "Winner should not be zero address");
        (bool winnerTransferSuccess,) = _winner.call{value : awardPrice}(""); 
        require(winnerTransferSuccess, "Betting.resultAuction: Failed to send the winner their award");
        
        emit BettingResulted(_winner, cryptprice, awardPrice);
    } 


    /**
     @notice Records the Ether price that a given token was sold for (in WEI)
     @dev Only admin or a smart contract can call this method
     @param _tokenId The ID of the token being updated
     @param _salePrice The primary Ether sale price in WEI
     */
    function setPrimarySalePrice(uint256 _tokenId, uint256 _salePrice) external {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "BettingNFT.mint: Sender must have the admin or contract role"
        );
        require(_exists(_tokenId), "BettingNFT.setPrimarySalePrice: Token does not exist");
        require(_salePrice > 0, "BettingNFT.setPrimarySalePrice: Invalid sale price");

        // Only set it once
        if (primarySalePrice[_tokenId] == 0) {
            primarySalePrice[_tokenId] = _salePrice;
            emit TokenPrimarySalePriceSet(_tokenId, _salePrice);
        }
    }

    /**
     @notice set the awardprice (in WEI)
     @dev Only admin or a smart contract can call this method
     @param _awardPrice The primary Ether sale price in WEI
     */
    function setAwardPrice(uint256 _awardPrice) external {
        require(
            accessControls.hasAdminRole(_msgSender()) || accessControls.hasSmartContractRole(_msgSender()),
            "BettingNFT.mint: Sender must have the admin or contract role"
        );
        require(_awardPrice > 0, "BettingNFT.setAwardPrice: Invalid award price");

        awardPrice = _awardPrice;
    }

    /**
     @notice Method for updating the access controls contract used by the NFT
     @dev Only admin
     @param _accessControls Address of the new access controls contract
     */
    function updateAccessControls(AccessControls _accessControls) external {
        require(accessControls.hasAdminRole(_msgSender()), "BettingNFT.updateAccessControls: Sender must be admin");
        accessControls = _accessControls;
    }
    /////////////////
    // View Methods /
    /////////////////

    /**
     @notice View method for checking whether a token has been minted
     @param _tokenId ID of the token being checked
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev checks the given token ID is approved either for all or the single token ID
     */
    function isApproved(uint256 _tokenId, address _operator) public view returns (bool) {
        return isApprovedForAll(ownerOf(_tokenId), _operator) || getApproved(_tokenId) == _operator;
    }

    /**
     * @dev get all information of token Id
     */
    function getNFTDetailByTokenId(uint256 tokenId) external view returns (
        uint256 _tokenId, 
        address _owner, 
        uint256 _tokenPrice, 
        uint256 _bucketStartPrice
    ) {
        return (tokenId, ownerOf(tokenId), primarySalePrice[tokenId], bucketpriceBytoken[tokenId]);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

}
