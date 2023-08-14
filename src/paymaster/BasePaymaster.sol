// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {IPaymaster} from "./ITruePaymaster.sol";
import {IEntryPoint} from "../interfaces/IEntryPoint.sol";
import {UserOperation} from "../interfaces/UserOperation.sol";

/**
 * Helper class for creating a paymaster.
 * provides helper methods for staking.
 * validates that the postOp is called only by the entryPoint
 */
/// @notice Based on Paymaster in: https://github.com/eth-infinitism/account-abstraction
abstract contract BasePaymaster is IPaymaster, Owned {
    IEntryPoint public entryPoint;

    event UpdateEntryPoint(
        address indexed newEntryPoint,
        address indexed oldEntryPoint
    );

    /// @notice Validate that only the entryPoint is able to call a method
    modifier onlyEntryPoint() {
        if (msg.sender != address(entryPoint)) {
            revert InvalidEntryPoint(msg.sender);
        }
        _;
    }

    /// @dev Reverts in case not valid entryPoint
    error InvalidEntryPoint(address sender);

    constructor(address _entryPoint, address _owner) Owned(_owner) {
        entryPoint = IEntryPoint(_entryPoint);
    }

    /// @notice Get the total paymaster stake on the entryPoint
    function getStake() public view returns (uint112) {
        return entryPoint.getDepositInfo(address(this)).stake;
    }

    /// @notice Get the total paymaster deposit on the entryPoint
    function getDeposit() public view returns (uint112) {
        return entryPoint.getDepositInfo(address(this)).deposit;
    }

    /// @notice Set the entrypoint contract, restricted to onlyOwner
    function setEntryPoint(address _newEntryPoint) external onlyOwner {
        emit UpdateEntryPoint(_newEntryPoint, address(entryPoint));
        entryPoint = IEntryPoint(_newEntryPoint);
    }

    /////////////////  VALIDATE USER OPERATIONS ///////////////

    /// @inheritdoc IPaymaster
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    )
        external
        override
        onlyEntryPoint
        returns (bytes memory context, uint256 validationData)
    {
        // Pay for all transactions from everyone, with no check
        return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal virtual returns (bytes memory context, uint256 validationData);

    /// @inheritdoc IPaymaster
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external override onlyEntryPoint {
        _postOp(mode, context, actualGasCost);
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal virtual {
        (mode, context, actualGasCost); // unused params
        // subclass must override this method if validatePaymasterUserOp returns a context
        revert("must override");
    }

    /////////////////  STAKE MANAGEMENT ///////////////

    /// @notice Add stake for this paymaster to the entryPoint. Used to allow the paymaster to operate and prevent DDOS
    /// @param unstakeDelaySeconds - the unstake delay for this paymaster. Can only be increased.
    function addStake(uint32 unstakeDelaySeconds) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySeconds);
    }

    /// @notice Unlock paymaster stake
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    /// @notice Withdraw paymaster stake, after having unlocked
    function withdrawStake(address payable to) external onlyOwner {
        entryPoint.withdrawStake(to);
    }

    /////////////////  DEPOSIT MANAGEMENT ///////////////

    /// @notice Add a deposit for this paymaster to the EntryPoint. Deposit is used to pay user gas fees
    function deposit() external payable virtual; // {

    // entryPoint.depositTo{value: msg.value}(address(this));
    // }

    /// @notice Withdraw paymaster deposit to an address
    function withdrawTo(address payable to, uint256 amount) external virtual; // {
    // entryPoint.withdrawTo(to, amount);
    // }

    // /// @notice Withdraw all paymaster deposit to an address
    // function withdrawAll(address payable to) external onlyOwner {
    //     uint112 totalDeposit = getDeposit();
    //     entryPoint.withdrawTo(to, totalDeposit);
    // }
}
