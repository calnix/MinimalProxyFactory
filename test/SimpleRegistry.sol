// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

/**
@notice Mock Implementation contract
*/

contract SimpleNameRegister is OwnableUpgradeable {
    
    bool private init;

    error AlreadyInitialised();

    /// @notice Map a name to an address to identify current holder 
    mapping (string => address) public holder;    

    /// @notice Emit event when a name is registered
    event Register(address indexed holder, string name);

    /// @notice Emit event when a name is released
    event Release(address indexed holder, string name);

    /// @notice User can register an available name
    /// @param name The string to register
    function register(string calldata name) external {
        require(holder[name] == address(0), "Already registered!");
        holder[name] = msg.sender;
        emit Register(msg.sender, name);
    }

    /// @notice Holder can release a name, making it available
    /// @param name The string to release
    function release(string calldata name) external {
        require(holder[name] == msg.sender, "Not your name!");
        delete holder[name];
        emit Release(msg.sender, name);
    }

    /// @notice To be run on deployment to initialise contract
    /// @dev Execution within function is subject to implementer's choice
    function initialise() external initializer {
        // 
        if (init == true){
            revert AlreadyInitialised();
        }

        init = true; 
        __Ownable_init();
    }


}