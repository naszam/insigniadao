pragma solidity 0.6.6;

/// @title Non-transferable Badges for Maker Ecosystem Activity, issue #537
/// @author Nazzareno Massari, Scott Herren, Bryan Flynn
/// @notice BadgeFactory to manage Templates and Badges
/// @dev see https://github.com/makerdao/community/issues/537
/// @dev All function calls are currently implemented without side effecs through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

import "./BadgeRoles.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

contract BadgeFactory is BadgeRoles, ERC721Burnable, ERC721Holder {

  using SafeMath for uint256;
  using Address for address;

  /*
      Badge metadata format
      {
          "title": "Project Proof Badge Metadata",
          "type": "object",
          "properties": {
              "name": {
                  "type": "string",
                  "description": "Identifies the badge template to which this NFT represents",
              },
              "description": {
                  "type": "string",
                  "description": "Describes the asset to which this NFT represents",
              },
              "image": {
                  "type": "string",
                  "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive.",
              },
              "unit_id": {
                  "type": "integer",
                  "description": "Specifies the id of this unit within its kind",
              }
          }
      }
  */

  event NewTemplate(uint256 communityId, string name, string description, string image, uint256 limit);
  event NewBadge(uint256 tokenId, uint256 templateId, string tokenURI);

  struct BadgeTemplate {
    string name;
    string description;
    string image;
    address owner;
    uint256 limit;
  }

  BadgeTemplate[] private templates;

  // Supplies of each badge template
  mapping(uint256 => uint256) private _templateQuantities;
  mapping(uint256 => uint256) private _tokenTemplates;

  constructor()
    ERC721("ProjectProof", "PROOF")
    public
  {

  }

  modifier onlyTemplateOwner(uint _templateId) {
    require(bytes(templates[_templateId].name).length != 0, "Template needs to exist");
    require(templates[_templateId].owner == msg.sender, "You do not own this template");
    _;
  }

  function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
    _mint(to, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return true;
  }

  function _hasTemplate(address add, uint256 templateId) internal view returns (bool) {
    require(templates.length > templateId, "No template with that id");
    require(templates[templateId].owner == add, "The community does not own the template");
    return true;
  }

  // Getters

  function getTemplate(uint256 templateId) public view returns (string memory name, string memory description, string memory image, uint256 limit) {
    require(templates.length > templateId, "No template with that id");
    BadgeTemplate memory template = templates[templateId];
    return (template.name, template.description, template.image, template.limit);
  }


  // Templates

  function getTemplatesCount() public view returns (uint256 count) {
    return templates.length;
  }

  function createTemplate(string memory name, string memory description, string memory image, uint256 limit) public onlyMinter returns (uint256 _templateId) {

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

  function destroyTemplate(uint256 templateId) public onlyTemplateOwner(templateId) {

    _hasTemplate(msg.sender, templateId);
    require(_templateQuantities[templateId] == 0, "Cannnot remove a template that has badges");

    templates[templateId] = templates[templates.length.sub(1)];
    templates.pop();
  }

  // Badges

  function getBadgeTemplate(uint256 tokenId) public view returns (uint256) {
    require(totalSupply() > tokenId, "No token with that id");
    return _tokenTemplates[tokenId];
  }

  function getBadgeTemplateQuantity(uint256 templateId) public view returns (uint256) {
    require(templates.length > templateId, "No template with that id");
    return _templateQuantities[templateId];
  }

  function createBadge(address to, uint256 templateId, string memory tokenURI) public onlyTemplateOwner(templateId) returns (uint256 _tokenId) {

    _hasTemplate(msg.sender, templateId);
    require(_templateQuantities[templateId] < templates[templateId].limit,
      "You have reached the limit of NFTs");
    _tokenId = totalSupply();
    mintWithTokenURI(
      to,
      _tokenId,
      tokenURI
    );

    // Increase the quantities
    _tokenTemplates[_tokenId] = templateId;
    _templateQuantities[templateId] = _templateQuantities[templateId].add(1);
    emit NewBadge(_tokenId, templateId, tokenURI);
    return _tokenId;
  }

  function burnBadge(uint256 tokenId) public {
    uint256 templateId = getBadgeTemplate(tokenId);
    burn(tokenId);
    _templateQuantities[templateId] = _templateQuantities[templateId].sub(1);
  }

  function _transfer(address from, address to, uint256 tokenId) internal override {
    require(!true, "ERC721: token transfer disabled");
    super._transfer(from, to, tokenId);
  }
}
