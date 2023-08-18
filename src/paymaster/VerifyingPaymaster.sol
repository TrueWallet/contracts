// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/* solhint-disable reason-string */
/* solhint-disable no-inline-assembly */

import {ITruePaymaster} from "./ITruePaymaster.sol";
import {IEntryPoint} from "../interfaces/IEntryPoint.sol";
import {UserOperationLib, UserOperation} from "../interfaces/UserOperation.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Owned} from "solmate/auth/Owned.sol";
import "src/helper/Helpers.sol";

import "lib/forge-std/src/console.sol";

/**
 * A paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for the account-specific signature:
 * - the paymaster checks a signature to agree to PAY for GAS.
 * - the account checks a signature to prove identity and account ownership.
 */
contract VerifyingPaymaster is ITruePaymaster, Owned {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;

    IEntryPoint public entryPoint;

    address public immutable verifyingSigner;

    uint256 private constant VALID_TIMESTAMP_OFFSET = 20;

    uint256 private constant SIGNATURE_OFFSET = 84;

    mapping(address => uint256) public senderNonce;

    event UpdateEntryPoint(
        address indexed _newEntryPoint,
        address indexed _oldEntryPoint
    );

    /// @notice Validate that only the entryPoint is able to call a method
    modifier onlyEntryPoint() {
        if (msg.sender != address(entryPoint)) {
            revert InvalidEntryPoint();
        }
        _;
    }

    /// @dev Reverts in case not valid entryPoint or owner
    error InvalidEntryPoint();

    constructor(
        IEntryPoint _entryPoint,
        address _verifyingSigner,
        address _owner
    ) Owned(_owner) {
        entryPoint = IEntryPoint(_entryPoint);
        verifyingSigner = _verifyingSigner;
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

    ////// VALIDATE USER OPERATIONS

    /**
     * Verify our external signer signed this request.
     * the "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     * paymasterAndData[:20] : address(this)
     * paymasterAndData[20:84] : abi.encode(validUntil, validAfter)
     * paymasterAndData[84:] : signature
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) external returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);
        (
            uint48 validUntil,
            uint48 validAfter,
            bytes calldata signature
        ) = parsePaymasterAndData(userOp.paymasterAndData);
        // ECDSA library supports both 64 and 65-byte long signatures.
        // we only "require" it here so that the revert reason on invalid signature will be of "VerifyingPaymaster", and not "ECDSA"
        require(
            signature.length == 64 || signature.length == 65,
            "VerifyingPaymaster: invalid signature length in paymasterAndData"
        );
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            getHash(userOp, validUntil, validAfter)
        );
        senderNonce[userOp.getSender()]++;

        // don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (verifyingSigner != ECDSA.recover(hash, signature)) {
            // console.log("SIG_VALIDATION_FAILED");
            return ("", _packValidationData(true, validUntil, validAfter));
        }

        // no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return ("", _packValidationData(false, validUntil, validAfter));
    }

    /**
     * Return the hash we're going to sign off-chain (and validate on-chain)
     * this method is called by the off-chain service, to sign the request.
     * it is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * note that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     */
    function getHash(
        UserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.

        return
            keccak256(
                abi.encode(
                    pack(userOp),
                    block.chainid,
                    address(this),
                    senderNonce[userOp.getSender()],
                    validUntil,
                    validAfter
                )
            );
    }

    function parsePaymasterAndData(
        bytes calldata paymasterAndData
    )
        public
        pure
        returns (uint48 validUntil, uint48 validAfter, bytes calldata signature)
    {
        (validUntil, validAfter) = abi.decode(
            paymasterAndData[VALID_TIMESTAMP_OFFSET:SIGNATURE_OFFSET],
            (uint48, uint48)
        );
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

    function pack(
        UserOperation calldata userOp
    ) internal pure returns (bytes memory ret) {
        // lighter signature scheme
        bytes calldata pnd = userOp.paymasterAndData;
        // copy directly the userOp from calldata up to (but not including) the paymasterAndData.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(pnd.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    /// @notice Handler for charging the sender (smart wallet) for the transaction after it has been paid for by the paymaster
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external onlyEntryPoint {}

    ///// STAKE MANAGEMENT

    /// @notice Add stake for this paymaster to the EntryPoint. Used to allow the paymaster to operate and prevent DDOS
    function addStake(uint32 _unstakeDelaySeconds) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(_unstakeDelaySeconds);
    }

    /// @notice Unlock paymaster stake
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    /// @notice Withdraw paymaster stake, after having unlocked
    function withdrawStake(address payable to) external onlyOwner {
        entryPoint.withdrawStake(to);
    }

    ///// DEPOSIT MANAGEMENT

    /// @notice Add a deposit for this paymaster to the EntryPoint. Deposit is used to pay user gas fees
    function deposit() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw paymaster deposit to an address
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        entryPoint.withdrawTo(to, amount);
    }

    /// @notice Withdraw all paymaster deposit to an address
    function withdrawAll(address payable to) external onlyOwner {
        uint112 totalDeposit = getDeposit();
        entryPoint.withdrawTo(to, totalDeposit);
    }
}
