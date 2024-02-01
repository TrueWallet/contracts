// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {TrueWallet} from "src/wallet/TrueWallet.sol";
import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {TrueContractManager} from "src/registry/TrueContractManager.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {SocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";

/// @title Deploy Code Generator.
/// @notice Provides functions to generate creation bytecode for various contracts.
contract DeployCodeGenerator {
    /// @notice Retrieves the creation bytecode of the TrueWalletFactory contract.
    /// @dev Combines TrueWalletFactory creation bytecode with encoded constructor parameters.
    /// @param _walletImpl Address of the wallet implementation contract.
    /// @param _owner Address of the owner for the TrueWalletFactory contract.
    /// @param _entryPoint Address of the entry point contract.
    /// @return bytecode The bytecode used to deploy the TrueWalletFactory contract.
    function getTrueWalletFactoryCode(address _walletImpl, address _owner, address _entryPoint)
        external
        pure
        returns (bytes memory)
    {
        bytes memory encodeInitParams = abi.encode(address(_walletImpl), address(_owner), address(_entryPoint));
        return abi.encodePacked(type(TrueWalletFactory).creationCode, encodeInitParams);
    }

    /// @notice Retrieves the creation bytecode of the TrueContractManager contract.
    /// @dev Combines TrueContractManager creation bytecode with encoded constructor parameter.
    /// @param _owner Address of the owner for the TrueContractManager contract.
    /// @return bytecode The bytecode used to deploy the TrueContractManager contract.
    function getTrueContractManagerCode(address _owner) external pure returns (bytes memory) {
        bytes memory encodeInitParams = abi.encode(address(_owner));
        return abi.encodePacked(type(TrueContractManager).creationCode, encodeInitParams);
    }

    /// @notice Retrieves the creation bytecode of the SecurityControlModule contract.
    /// @dev Combines SecurityControlModule creation bytecode with encoded constructor parameter.
    /// @param _trueContractManager Address of the TrueContractManager contract.
    /// @return bytecode The bytecode used to deploy the SecurityControlModule contract.
    function getSecurityControlModuleCode(address _trueContractManager) external pure returns (bytes memory) {
        bytes memory encodeInitParams = abi.encode(address(_trueContractManager));
        return abi.encodePacked(type(SecurityControlModule).creationCode, encodeInitParams);
    }

    /// @notice Retrieves the creation bytecode of the SocialRecoveryModule contract.
    /// @dev Returns the creation bytecode of the SocialRecoveryModule contract.
    /// @return bytecode The bytecode used to deploy the SocialRecoveryModule contract.
    function getSocialRecoveryModuleCode() external pure returns (bytes memory) {
        return type(SocialRecoveryModule).creationCode;
    }

    /// @notice Retrieves the creation bytecode of the TrueWallet contract.
    /// @dev Returns the creation bytecode of the TrueWallet contract.
    /// @return bytecode The bytecode used to deploy the TrueWallet contract.
    function getTrueWalletImplCode() external pure returns (bytes memory) {
        return type(TrueWallet).creationCode;
    }
}
