/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title Non-transferable Badges for Maker Ecosystem Activity, CDIP 18
/// @author Nazzareno Massari @naszam
/// @notice BadgePaymaster to pay for user's transaction fees
/// @dev see https://github.com/makerdao/community/issues/537
/// @dev All function calls are currently implemented without side effecs through TDD approach
/// @dev OpenZeppelin library is used for secure contract development

import "@opengsn/gsn/contracts/forwarder/IForwarder.sol";
import "@opengsn/gsn/contracts/BasePaymaster.sol";

contract BadgePaymaster is BasePaymaster {

    /// @dev Target Contracts to pay for
    mapping(address => bool) public validTargets;

  	/// @dev Events
  	event TargetSet(address target);
    event PreRelayed(uint);
  	event PostRelayed(uint);

    function setTarget(address target) external onlyOwner {
    		validTargets[target] = true;
    		emit TargetSet(target);
  	}

  	function preRelayedCall(
  		  GsnTypes.RelayRequest calldata relayRequest,
  		  bytes calldata signature,
  		  bytes calldata approvalData,
  		  uint256 maxPossibleGas
  	)
        override
        virtual
        external
  	    returns (bytes memory context, bool)
    {
    		(signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);
        require(validTargets[relayRequest.request.to], "not a registered target");
    		emit PreRelayed(now);
        return (abi.encode(now), false);
  	}

  	function postRelayedCall(
    		bytes calldata context,
    		bool success,
    		uint256 gasUseWithoutPost,
    		GsnTypes.RelayData calldata relayData
  	)
        external
        override
        virtual
    {
        (context, success, gasUseWithoutPost, relayData);
    		emit PostRelayed(abi.decode(context, (uint)));
  	}

    function deposit() public payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    function withdrawAll(address payable destination) public {
        uint256 amount = relayHub.balanceOf(address(this));
        withdrawRelayHubDepositTo(amount, destination);
    }

    function versionPaymaster() external virtual view override returns (string memory) {
        return "0.6.0";
    }

}
