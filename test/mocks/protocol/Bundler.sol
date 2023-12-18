// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {EntryPoint} from "test/mocks/protocol/EntryPoint.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {DecodeCalldata} from "src/libraries/DecodeCalldata.sol";

contract Bundler is Test {
    function post(IEntryPoint entryPoint, UserOperation memory userOp) external {
        // staticcall: function simulateValidation(UserOperation calldata userOp) external

        if (true) {
            uint256 snapshotId = vm.snapshot();

            (bool success, bytes memory data) = address(entryPoint).call(
                abi.encodeWithSignature(
                    "simulateValidation((address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes))",
                    userOp
                )
            );

            vm.revertTo(snapshotId);

            if (!success) {
                bytes4 methodId = DecodeCalldata.decodeMethodId(data);
                if (methodId == IEntryPoint.ValidationResult.selector) {
                    // error ValidationResult(ReturnInfo returnInfo, StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);
                } else {
                    if (methodId == IEntryPoint.FailedOp.selector) {
                        // error FailedOp(uint256 opIndex, string reason);
                        bytes memory _data = DecodeCalldata.decodeMethodCalldata(data);
                        (uint256 opIndex, string memory reason) = abi.decode(_data, (uint256, string));
                        console.log("FailedOp: ", opIndex, reason);
                        // revert IEntryPoint.FailedOp(opIndex, reason);
                    }

                    assembly {
                        revert(add(data, 0x20), mload(data))
                    }
                }
            } else {
                revert("failed");
            }
        }

        UserOperation[] memory userOperations = new UserOperation[](1);
        userOperations[0] = userOp;
        // address payable beneficiary = payable(makeAddr("beneficiary"));
        // uint256 gas_before = gasleft();
        entryPoint.handleOps(userOperations, payable(msg.sender)); //beneficiary
        // uint256 gas_after = gasleft();
        // console.log("entryPoint.handleOps => gas: ", gas_before - gas_after);
    }
}
