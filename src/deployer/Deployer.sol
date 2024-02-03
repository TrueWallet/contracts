// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {Ownable} from "solady/auth/Ownable.sol";
import {CREATE3} from "solady/utils/CREATE3.sol";

/// @title Deployer
/// @notice A contract for deploying other contracts using CREATE3 to achieve deterministic addresses.
/// @dev This contract utilizes the CREATE3 library to enable deterministic deployment of contracts, allowing for the same contract address across different EVM-compatible blockchains.
contract Deployer is Ownable {
    /// @notice Emitted when a contract is successfully deployed.
    event ContractDeployed(address indexed contractAddress);

    /// @dev Initializes the Deployer contract, setting the initial owner to the provided address.
    /// @param _owner The address that will be granted ownership of this contract, capable of performing deployments.
    constructor(address _owner) {
        _setOwner(_owner);
    }

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
