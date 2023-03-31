// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {IPaymaster} from "../interfaces/IPaymaster.sol";

interface ITruePaymaster is IPaymaster {
    /// @notice Get the Paymaster stake on the entryPoint, which is used for DDOS protection.
    function getStake() external view returns (uint112);

    /// @notice Get the Paymaster deposit on the entryPoint, which is used to pay for gas.
    function getDeposit() external view returns (uint112);

    /// @notice Add a deposit for this paymaster to the entryPoint.
    function deposit() external payable;

    /// @notice Add to the account's stake - amount and delay.
    function addStake(uint32 _unstakeDelaySeconds) external payable;
}