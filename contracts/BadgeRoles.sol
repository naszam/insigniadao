/// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

/// @title Non-transferable Badges for Maker Ecosystem Activity, CDIP 18, 29
/// @author Nazzareno Massari @naszam
/// @notice BadgeRoles Access Management for Default Admin, Templater and Pauser Role
/// @dev See https://github.com/makerdao/community/issues/537
/// @dev See https://github.com/makerdao/community/issues/721
/// @dev All function calls are currently implemented without side effects through TDD approach
/// @dev OpenZeppelin Library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";
import "@opengsn/gsn/contracts/interfaces/IKnowForwarderAddress.sol";


contract BadgeRoles is Ownable, AccessControl, Pausable, BaseRelayRecipient, IKnowForwarderAddress {

    /// @dev Roles
    bytes32 public constant TEMPLATER_ROLE = keccak256("TEMPLATER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(address forwarder_) public {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        _setupRole(TEMPLATER_ROLE, owner());
        _setupRole(PAUSER_ROLE, owner());

        /// @dev OpenGSN Trusted Forwarder
        trustedForwarder = forwarder_;
    }

    /// @dev Modifiers
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BadgeFactory: caller is not an admin");
        _;
    }

    modifier onlyTemplater() {
        require(hasRole(TEMPLATER_ROLE, _msgSender()), "BadgeFactory: caller is not a template owner");
        _;
    }

    /// @dev Functions

    /// @notice Add a new Templater
    /// @dev Access restricted only for Admins
    /// @param guy Address of the new Templater
    /// @return True if the guy address is added as Templater
    function addTemplater(address guy) external onlyAdmin returns (bool) {
        require(!hasRole(TEMPLATER_ROLE, guy), "BadgeFactory: guy is already a templater");
        grantRole(TEMPLATER_ROLE, guy);
        return true;
    }

    /// @notice Remove a Templater
    /// @dev Access restricted only for Admins
    /// @param guy Address of the Templater
    /// @return True if the guy address is removed as Templater
    function removeTemplater(address guy) external onlyAdmin returns (bool) {
        require(hasRole(TEMPLATER_ROLE, guy), "BadgeFactory: guy is not a templater");
        revokeRole(TEMPLATER_ROLE, guy);
        return true;
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "BadgeFactory: must have pauser role to pause");
        _pause();
    }

    /// @notice Unpause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function unpause() external {
        require(hasRole(PAUSER_ROLE, _msgSender()), "BadgeFactory: must have pauser role to unpause");
        _unpause();
    }

    function versionRecipient() external virtual view override returns (string memory) {
        return "0.6.0";
    }

    function getTrustedForwarder() public view override returns (address) {
        return trustedForwarder;
    }

    /// @notice OpenGSN _msgSender()
    /// @dev override _msgSender() in OZ Context.sol and BaseRelayRecipient.sol
    /// @return _msgSender() after relay call
    function _msgSender() internal virtual view override(Context, BaseRelayRecipient) returns (address payable) {
          return BaseRelayRecipient._msgSender();
    }
}
