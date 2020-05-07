pragma solidity 0.6.7;

/// @title Non-transferable Badges for Maker Ecosystem Activity, issue #537
/// @author Nazzareno Massari, Scott Herren, Bryan Flynn
/// @notice BadgeFactory to manage Templates and activate Non-transferable Badges for redeemers
/// @dev see https://github.com/makerdao/community/issues/537
/// @dev All function calls are currently implemented without side effecs through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

import "./BadgeRoles.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

interface InsigniaDAO {

    function verify(address guy) external view returns (bool);

}

contract BadgeFactory is BadgeRoles, ERC721Burnable {

  /// Libraries
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;
  using MerkleProof for bytes32[];

  Counters.Counter private _tokenIdTracker;

  InsigniaDAO internal insignia;

  /// Events
  event NewTemplate(uint256 templateId, string name, string description, string image, uint256 limit);
  event TemplateDestroyed(uint templateId);
  event BadgeActivated(address redeemer, uint256 tokenId, uint256 templateId, string tokenURI);

  struct BadgeTemplate {
    string name;
    string description;
    string image;
    address owner;
    uint256 limit;
  }

  BadgeTemplate[] private templates;

  /// Supplies of each badge template
  mapping(uint256 => uint256) private _templateQuantities;
  mapping(uint256 => uint256) private _tokenTemplates;

  constructor(address insignia_)
    ERC721("InsigniaBadges", "BADGES")
    public
  {
    _setBaseURI("https://badges.makerdao.com/token/");
    insignia = InsigniaDAO(insignia_);

  }

  /// @notice Fallback function
  /// @dev Added not payable to revert transactions not matching any other function which send value
  fallback() external {
    revert();
  }

  /// @notice Set the baseURI
  /// @dev Update the baseURI specified in the constructor
  /// @param baseURI New baseURI
  /// @return True if the new baseURI is set
  function setBaseURI(string memory baseURI) public onlyOwner returns (bool) {
    _setBaseURI(baseURI);
    return true;
  }

  /// @notice Mint new token with tokenURI
  /// @dev Use an auto-generated tokenId
  /// @dev automatically concatenate baseURI with tokenURI via abi.encodePacked
  /// @param to owner of the new token
  /// @param tokenURI an <ipfs-hash>.json filename
  /// @return True if the new token is minted
  function _mintWithTokenURI(address to, string memory tokenURI) internal returns (bool) {
    _mint(to, _tokenIdTracker.current());
    _setTokenURI(_tokenIdTracker.current(), tokenURI);
    _tokenIdTracker.increment();
    return true;
  }

  /// @notice Check if templateId exists and its owned by templater
  /// @dev Internal function to check for templateId and caller
  /// @param templater Address to check as the owner of the template
  /// @param templateId Template Id to check if existent
  /// @return True if the templateId exists and its owned by address add
  function _hasTemplate(address templater, uint256 templateId) internal view returns (bool) {
    require(templates.length > templateId, "No template with that id");
    require(templates[templateId].owner == templater, "The community does not own the template");
    return true;
  }

  /// @notice Getter function for templates
  /// @dev Check if templateId exists
  /// @param templateId Template Id of the template to return
  /// @return name description image limit of the specified templateId
  function getTemplate(uint256 templateId) public view whenNotPaused returns (string memory name, string memory description, string memory image, uint256 limit) {
    require(templates.length > templateId, "No template with that id");
    BadgeTemplate memory template = templates[templateId];
    return (template.name, template.description, template.image, template.limit);
  }


  // Templates

  function getTemplatesCount() public view whenNotPaused returns (uint256 count) {
    return templates.length;
  }

  function createTemplate(string memory name, string memory description, string memory image, uint256 limit) public onlyTemplater whenNotPaused returns (uint256 _templateId) {

    BadgeTemplate memory _newTemplate = BadgeTemplate({
       name: name,
       owner: msg.sender,
       description: description,
       image: image,
       limit: limit
    });
    templates.push(_newTemplate);
    _templateId = templates.length.sub(1);
    emit NewTemplate(_templateId, name, description, image, limit);
    return _templateId;
  }

  function destroyTemplate(uint256 templateId) public onlyTemplater whenNotPaused returns (bool) {

    _hasTemplate(msg.sender, templateId);
    require(_templateQuantities[templateId] == 0, "Cannnot remove a template that has badges");

    templates[templateId] = templates[templates.length.sub(1)];
    templates.pop();
    emit TemplateDestroyed(templateId);
    return true;
  }

  // Badges

  function getBadgeTemplate(uint256 tokenId) public view whenNotPaused returns (uint256) {
    require(totalSupply() > tokenId, "No token with that id");
    return _tokenTemplates[tokenId];
  }

  function getBadgeTemplateQuantity(uint256 templateId) public view whenNotPaused returns (uint256) {
    require(templates.length > templateId, "No template with that id");
    return _templateQuantities[templateId];
  }

  function activateBadge(bytes32[] memory proof, bytes32 root, uint256 templateId, string memory tokenURI) public whenNotPaused returns (uint256 _tokenId) {
    require(templates.length > templateId, "No template with that id");
    require(_templateQuantities[templateId] < templates[templateId].limit,
      "You have reached the limit of NFTs");
    require(insignia.verify(msg.sender) || proof.verify(root, keccak256(abi.encodePacked(msg.sender))), "Caller is not a redeemer");

    _mintWithTokenURI(
      msg.sender,
      tokenURI
    );

    // Increase the quantities
    _tokenTemplates[_tokenId] = templateId;
    _templateQuantities[templateId] = _templateQuantities[templateId].add(1);
    emit BadgeActivated(msg.sender,_tokenId, templateId, tokenURI);
    return _tokenId;
  }

  function burnBadge(uint256 tokenId) public whenNotPaused returns (bool){
    uint256 templateId = getBadgeTemplate(tokenId);
    burn(tokenId);
    _templateQuantities[templateId] = _templateQuantities[templateId].sub(1);
    return true;
  }

  function _transfer(address from, address to, uint256 tokenId) internal override {
    require(!true, "ERC721: token transfer disabled");
    super._transfer(from, to, tokenId);
  }

}
