// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MinimalProxyFactory is Ownable {
    
    // EVENTS
    event ProxyCreated(address indexed proxy);

    /// @dev Deploys a new minimal contract via create2
    /// @param implementation Address of Implementation contract
    /// @param salt Random number of choice for create2
    function deploy(address implementation, uint256 salt) external returns (address) {
        
        // cast address as bytes
        bytes20 implementationBytes = bytes20(implementation);

        // minimal proxy address
        address proxy;

        assembly {
            
            // free memory pointer
            let pointer := mload(0x40)
        
            // mstore 32 bytes at the start of free memory 
            mstore(pointer, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)

            // overwrite the trailing 0s above with implementation contract's byte address 
            mstore(add(pointer, 0x14), implementationBytes)
           
            // store 32 bytes to memory starting at "clone" + 40 bytes
            mstore(add(pointer, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            // create a new contract, send 0 Ether
            proxy := create2(0, pointer, 0x37, salt)
        }

        _initialiseProxy(proxy);

        emit ProxyCreated(proxy);
        return proxy;
    }

    /// @dev Initialise minimal proxy
    /// @param proxy Address of target minimal proxy for init
    function _initialiseProxy(address proxy) internal {
        bytes memory data = abi.encodeWithSignature("initialise()");
        (bool success, ) = proxy.call(data);
        require(success);
    }

    /// @dev Transfer ownership
    /// @param proxy Address of target minimal proxy
    /// @param newOwner Address of new owner
    function changeOwner(address proxy, address newOwner) external onlyOwner {
        bytes memory data = abi.encodeWithSignature("transferOwnership(address)", newOwner);
        (bool success, ) = proxy.call(data);
        require(success);
    }

    /// @dev For execution of generic fn calls
    /// @param proxy Address of target minimal proxy
    /// @param data Function selection and requisite arguments
    function execute(address proxy, bytes calldata data) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = proxy.call(data);
        require(success);

        return result;
    }

    /// @dev Get address of contract to be deployed
    /// @param salt Random number of choice
    /// @param implementation Address of Implementation contract
    /// Note: When calculating the deployment address we need to use the creation code for the minimal proxy, 
    //        not the logic contract that the minimal proxy points to
    function getAddress(address implementation, uint256 salt) public view returns (address) {
        //bytes32 salt = keccak256(abi.encodePacked(salt, _sender));
        bytes memory bytecode = getByteCode(implementation);

        // find hash
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

        // cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @dev Get creation code of contract to deploy
    /// @param implementation Address of Implementation contract proxy will delegateCall to 
    /// @return bytes Bytecode of creaton code to be passed into getAddress()
    function getByteCode(address implementation) internal pure returns (bytes memory) {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 prefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(implementation);
        bytes15 suffix = 0x5af43d82803e903d91602b57fd5bf3;
        
        return abi.encodePacked(creation, prefix, targetBytes, suffix);
    }

}