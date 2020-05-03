pragma solidity 0.6.6;

/// @title Non-transferable Badges for Maker Ecosystem Activity, issue #537
/// @author Nazzareno Massari, Scott Herren, Bryan Flynn
/// @notice InsigniaDAO to check for activities on maker system and activate badges
/// @dev see https://github.com/makerdao/community/issues/537
/// @dev All function calls are currently implemented without side effecs through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface PotLike {

    function pie(address guy) external view returns (uint256);
    function chi() external view returns (uint256);

}

contract InsigniaDAO is Ownable, AccessControl, Pausable {

  using SafeMath for uint256;
  using Address for address;
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  EnumerableSet.AddressSet private redeemers;

  // Events
  event DSRChallengeChecked(address guy);

  // Data
  PotLike  internal pot;


  // Math

  uint constant WAD = 10 ** 18;

  function wmul(uint x, uint y) internal view whenNotPaused returns (uint z) {
          // always rounds down
          z = x.mul(y) / WAD;
  }

  constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        _setupRole(PAUSER_ROLE, owner());

        // MCD_POT Kovan Address https://changelog.makerdao.com/releases/kovan/1.0.5/contracts.json
			  pot = PotLike(0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
	}

  function balance(address guy) internal view whenNotPaused returns (uint256) {
    uint256 slice = pot.pie(guy);
    uint256 chi = pot.chi();
    return wmul(slice, chi);
  }

  function dsrChallenge() public whenNotPaused returns (bool) {
    uint256 interest = balance(msg.sender);
    require(interest == 1 ether, "The caller has not accrued 1 Dai interest");
    redeemers.add(address(uint160(uint256(keccak256(abi.encodePacked(msg.sender))))));
    emit DSRChallengeChecked(msg.sender);
    return true;
  }

  function verify(address guy) public view whenNotPaused returns (bool) {
    require(redeemers.contains(address(uint160(uint256(keccak256(abi.encodePacked(guy)))))) == true, "The address is not a redeemer");
    return true;
  }

  /// @notice Pause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function pause() public {
    require(hasRole(PAUSER_ROLE, msg.sender), "InsigniaDAO: must have pauser role to pause");
    _pause();
  }

  /// @notice Unpause all the functions
  /// @dev the caller must have the 'PAUSER_ROLE'
  function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender), "InsigniaDAO: must have pauser role to unpause");
        _unpause();
    }

}
