// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {CREATE3} from "./Create3.sol";

/// @title A contract for deploying other contracts using CREATE3.
/// @notice This contract allows an owner to deploy contracts to deterministic addresses using CREATE3.
contract Deployer is Owned(msg.sender) {
    /// @notice Emitted when a contract is successfully deployed.
    event ContractDeployed(address indexed contractAddress);

    /// @notice Deploys a contract using a specific salt and creation code.
    /// @dev This function can only be called by the owner of the contract.
    /// @param _salt A unique salt value used to determine the contract's address.
    /// @param _creationCode The bytecode (including constructor parameters) of the contract to be deployed.
    /// @return contractAddress The address of the deployed contract.
    function deploy(bytes32 _salt, bytes calldata _creationCode) external onlyOwner returns (address contractAddress) {
        contractAddress = CREATE3.deploy(_salt, _creationCode, 0);

        emit ContractDeployed(contractAddress);
    }

    /// @notice Computes and returns the address of a contract deployed with a given salt.
    /// @dev This function does not change the state and can be called by anyone.
    /// @param _salt The salt value used in the contract's deployment.
    /// @return The address of the contract deployed with the given salt.
    function getContractAddress(bytes32 _salt) external view returns (address) {
        return CREATE3.getDeployed(_salt);
    }
}
