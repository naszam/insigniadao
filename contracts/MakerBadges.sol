/// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


/// @title Non-transferable Badges for Maker Ecosystem Activity, CDIP 18, 29
/// @author Nazzareno Massari @naszam
/// @notice MakerBadges to check on-chain for activities on maker ecosystem and keep track of redeemers
/// @dev See https://github.com/makerdao/community/issues/537
/// @dev See https://github.com/makerdao/community/issues/721
/// @dev All function calls are currently implemented without side effects through TDD approach
/// @dev OpenZeppelin Library is used for secure contract development

/*
███    ███  █████  ██   ██ ███████ ██████ 
████  ████ ██   ██ ██  ██  ██      ██   ██ 
██ ████ ██ ███████ █████   █████   ██████  
██  ██  ██ ██   ██ ██  ██  ██      ██   ██ 
██      ██ ██   ██ ██   ██ ███████ ██   ██ 
*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";

interface ChaiLike {
    function dai(address usr) external returns (uint256);
}

interface DSChiefLike {
    function votes(address) external view returns (bytes32);
}

interface VoteProxyLike {
    function cold() external view returns (address);
    function hot() external view returns (address);
}

interface FlipperLike {
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;
        uint48  tic;
        uint48  end;
        address usr;
        address gal;
        uint256 tab;
    }

    function bids(uint256) external view returns (Bid memory);
}

contract MakerBadges is AccessControl, Pausable, BaseRelayRecipient {

    /// @dev Libraries
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Data
    ChaiLike  internal immutable chai;
    DSChiefLike internal immutable chief;
    FlipperLike internal immutable flipper;
    VoteProxyLike internal proxy;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(uint256 => EnumerableSet.AddressSet) private redeemers;

    uint256 public constant chaiId = 0;
    uint256 public constant chiefId = 1;
    uint256 public constant robotId = 2;
    uint256 public constant flipperId = 3;

    /// @dev Events
    event ChaiChecked(address indexed usr);
    event DSChiefChecked(address indexed guy);
    event RobotChecked(address indexed guy);
    event FlipperChecked(address indexed guy);

    constructor(address forwarder_, address chai_, address chief_, address flipper_) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());

        /// @dev CHAI Address
        chai = ChaiLike(chai_);

        /// @dev MCD_ADM Address
        chief = DSChiefLike(chief_);

        /// @dev MCD_FLIP_ETH_A Address
        flipper = FlipperLike(flipper_);

        /// @dev Biconomy Trusted Forwarder
        trustedForwarder = forwarder_;
    }

    /// @notice Fallback function
    /// @dev Added not payable to revert transactions not matching any other function which send value
    fallback() external {
        revert("MakerBadges: function not matching any other");
    }

    /// @notice Chai Challenge
    /// @dev Keeps track of the address of the caller if successful
    function chaiChallenge() external whenNotPaused {
        require(redeemers[chaiId].add(_msgSender()), "MakerBadges: caller already checked for chai");
        emit ChaiChecked(_msgSender());
        require(chai.dai(_msgSender()) >= 1 ether, "MakerBadges: caller has not accrued 1 or more dai interest on pot");
    }


    /// @notice DSChief Challenge
    /// @dev Keeps track of the address of the caller if successful
    function chiefChallenge() external whenNotPaused {
        require(chief.votes(_msgSender()) != 0x00,"MakerBadges: caller is not voting in an executive spell");
        require(redeemers[chiefId].add(_msgSender()), "MakerBadges: caller already checked for chief");
        emit DSChiefChecked(_msgSender());
    }

    /// @notice Robot Challenge
    /// @dev Keeps track of the address of the caller if successful
    function robotChallenge(address _proxy) external whenNotPaused {
        proxy = VoteProxyLike(_proxy);
        require(
            chief.votes(_proxy)!= 0x00 && (proxy.cold() == _msgSender() || proxy.hot() == _msgSender()),
            "MakerBadges: caller is not voting via proxy in an executive spell"
        );
        require(redeemers[robotId].add(_msgSender()), "MakerBadges: caller already checked for robot");
        emit RobotChecked(_msgSender());
    }


    /// @notice Flipper Challenge
    /// @dev Keeps track of the address of the caller if successful
    /// @dev guy, high bidder
    function flipperChallenge(uint256 bidId) external whenNotPaused {
        require(
            flipper.bids(bidId).guy == _msgSender(),
            "MakerBadges: caller is not the high bidder in the current bid in ETH collateral auctions"
        );
        require(redeemers[flipperId].add(_msgSender()), "MakerBadges: caller already checked for flipper");
        emit FlipperChecked(_msgSender());
    }

    /// @notice Check if guy is a redeemer
    /// @dev Verify if the address of guy exists
    /// @param guy Address to verify
    /// @return True if guy is a redeemer
    function verify(uint256 templateId, address guy) external view whenNotPaused returns (bool) {
        return redeemers[templateId].contains(guy);
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MakerBadges: must have pauser role to pause");
        _pause();
    }

    /// @notice Unpause all the functions
    /// @dev The caller must have the 'PAUSER_ROLE'
    function unpause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MakerBadges: must have pauser role to unpause");
        _unpause();
    }

    function versionRecipient() external virtual view override returns (string memory) {
        return "0.9.0";
    }

    function getTrustedForwarder() external view returns (address) {
        return trustedForwarder;
    }

    /// @notice OpenGSN _msgSender()
    /// @dev override _msgSender() in OZ Context.sol and BaseRelayRecipient.sol
    /// @return _msgSender() after relay call
    function _msgSender() internal view override(Context, BaseRelayRecipient) returns (address payable) {
        return BaseRelayRecipient._msgSender();
    }

    /// @notice OpenGSN _msgData()
    /// @dev override _msgData() in OZ Context.sol and BaseRelayRecipient.sol
    /// @return _msgData() after relay call
    function _msgData() internal view override(Context, BaseRelayRecipient) returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }
}
