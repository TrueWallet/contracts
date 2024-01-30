// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {TrueWalletFactory} from "src/wallet/TrueWalletFactory.sol";
import {TrueContractManager} from "src/registry/TrueContractManager.sol";
import {SecurityControlModule} from "src/modules/SecurityControlModule/SecurityControlModule.sol";
import {SocialRecoveryModule} from "src/modules/SocialRecoveryModule/SocialRecoveryModule.sol";

// / @title A contract for deploying other contracts using CREATE3.
// / @notice This contract allows an owner to deploy contracts to deterministic addresses using CREATE3.
contract DeployCodeGenerator {
    /// @notice Retrieves the creation bytecode of the TrueWalletFactory contract.
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
    /// @return bytecode The bytecode used to deploy the TrueContractManager contract.
    function getTrueContractManagerCode(address _owner) external pure returns (bytes memory) {
        bytes memory encodeInitParams = abi.encode(address(_owner));
        return abi.encodePacked(type(TrueContractManager).creationCode, encodeInitParams);
    }

    /// @notice Retrieves the creation bytecode of the SecurityControlModule contract.
    /// @return bytecode The bytecode used to deploy the SecurityControlModule contract.
    function getSecurityControlModuleCode(address _trueContractManager) external pure returns (bytes memory) {
        bytes memory encodeInitParams = abi.encode(address(_trueContractManager));
        return abi.encodePacked(type(SecurityControlModule).creationCode, encodeInitParams);
    }

    /// @notice Retrieves the creation bytecode of the SocialRecoveryModule contract.
    /// @return bytecode The bytecode used to deploy the SocialRecoveryModule contract.
    function getSocialRecoveryModuleCode() external pure returns (bytes memory) {
        return type(SocialRecoveryModule).creationCode;
    }
}
