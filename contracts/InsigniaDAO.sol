pragma solidity 0.6.6;

/// @title Non-transferable Badges for Maker Ecosystem Activity, issue #537
/// @author Nazzareno Massari, Scott Herren, Bryan Flynn
/// @notice InsigniaDAO to check for activities on maker system and activate badges
/// @dev see https://github.com/makerdao/community/issues/537
/// @dev All function calls are currently implemented without side effecs through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface PotLike {

    function pie(address guy) external view returns (uint256);
    function chi() external view returns (uint256);

}

contract InsigniaDAO is Ownable, Pausable {

  using SafeMath for uint256;
  using Address for address;
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private redeemers;

  // Events
  event DSRChallengeChecked(address guy);

  // Data
  PotLike  internal pot;


  // Math

  uint constant WAD = 10 ** 18;

  function wmul(uint x, uint y) internal pure returns (uint z) {
          // always rounds down
          z = x.mul(y) / WAD;
  }

  constructor() public {

        // MCD_POT Kovan Address https://changelog.makerdao.com/releases/kovan/1.0.5/contracts.json
			  pot = PotLike(0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
	}

  function balance(address guy) internal view returns (uint256) {
    uint256 slice = pot.pie(guy);
    uint256 chi = pot.chi();
    return wmul(slice, chi);
  }

  function dsrChallenge() public returns (bool) {
    uint256 interest = balance(msg.sender);
    require(interest == 1, "The caller has not accrued 1 Dai interest");
    redeemers.add(msg.sender);
    emit DSRChallengeChecked(msg.sender);
    return true;
  }

  function verify(address guy) public view returns (bool) {
    require(redeemers.contains(guy) == true, "The address is not a redeemer");
    return true;
  }

}
