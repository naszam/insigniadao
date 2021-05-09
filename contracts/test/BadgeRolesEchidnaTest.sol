// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "../BadgeRoles.sol";

contract EchidnaInterface {
    address internal constant crytic_owner = address(0x41414141);
    //address constant internal crytic_user = address(0x42424242);
    //address constant internal crytic_attacker = address(0x43434343);
}

contract BadgeRolesEchidnaTest is EchidnaInterface, BadgeRoles {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, crytic_owner);
        _setupRole(ADMIN_ROLE, crytic_owner);
        _setupRole(TEMPLATER_ROLE, crytic_owner);
        _setupRole(PAUSER_ROLE, crytic_owner);
    }

    function crytic_default_admin_constant() external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, crytic_owner);
    }

    function crytic_admin_constant() external view returns (bool) {
        return hasRole(ADMIN_ROLE, crytic_owner);
    }

    function crytic_templater_constant() external view returns (bool) {
        return hasRole(TEMPLATER_ROLE, crytic_owner);
    }

    function crytic_pauser_constant() external view returns (bool) {
        return hasRole(PAUSER_ROLE, crytic_owner);
    }
}
