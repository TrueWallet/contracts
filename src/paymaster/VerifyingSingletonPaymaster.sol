// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/* solhint-disable reason-string */
/* solhint-disable no-inline-assembly */

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {UserOperationLib, UserOperation} from "../interfaces/UserOperation.sol";
import {BasePaymaster, IEntryPoint} from "src/paymaster/BasePaymaster.sol";
import {PaymasterHelpers, PaymasterData, PaymasterContext} from "src/paymaster/PaymasterHelper.sol";

import "forge-std/console.sol";

/**
 * @title A sample paymaster that uses external service to decide whether to pay for the UserOp.
 * @dev The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs whatever
 * off-chain verification before signing the UserOp.
 * @notice That this signature is NOT a replacement for wallet signature:
 *  - The paymaster signs to agree to PAY for GAS.
 *  - The wallet signs to prove identity and wallet ownership.
 */
contract VerifyingSingletonPaymaster is BasePaymaster, ReentrancyGuard {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using PaymasterHelpers for UserOperation;
    using PaymasterHelpers for PaymasterData;
    using PaymasterHelpers for bytes;

    /// @dev Gas used in EntryPoint._handlePostOp() method (including this#postOp() call)
    uint256 private unaccountedEPGasOverhead;
    mapping(address => uint256) public paymasterIdBalances;

    address public verifyingSigner;

    event EPGasOverheadChanged(uint256 indexed oldValue, uint256 indexed newValue);
    event VerifyingSingerChanged(address indexed oldSinger, address indexed newSigner, address indexed actor);
    event GasDeposited(address indexed paymasterId, uint256 indexed value);
    event GasWithdraw(address indexed paymasterId, address indexed to, uint256 indexed value);
    event GasBalanceDeducted(address indexed paymasterId, uint256 indexed change);

    error EntryPointCannotBeZero();
    error OwnerAddressCannotBeZero();
    error VerifyingSignerCannotBeZero();
    error PaymasterIdCannotBeZero();
    error DepositeCannotBeZero();
    error CanNotWithdrawToZeroAddress();
    error InsufficientBalance(uint256 amount, uint256 balance);
    error InvalidPaymasterSignatureLength(uint256 sigLength);

    constructor(
        address _entryPoint,
        address _owner,
        address _verifyingSigner
    ) payable BasePaymaster(_entryPoint, _owner) {
        if (address(_entryPoint) == address(0)) revert EntryPointCannotBeZero();
        if (_owner == address(0)) revert OwnerAddressCannotBeZero();
        if (_verifyingSigner == address(0)) revert VerifyingSignerCannotBeZero();

        assembly {
            sstore(verifyingSigner.slot, _verifyingSigner)
        }

        unaccountedEPGasOverhead = 9600;
    }

    /// @dev Get the current deposit for paymasterId (Dapp Depositor address)
    /// @param paymasterId dapp identifier
    function getBalance(address paymasterId) external view returns (uint256 balance) {
        balance = paymasterIdBalances[paymasterId];
    }    

    /// @dev Add a deposit for this paymaster and given paymasterId (Dapp Depositor address), used for paying for transaction fees
    /// @param paymasterId dapp identifier for which deposit is being made
    function depositeFor(address paymasterId) external payable nonReentrant {
        if (paymasterId == address(0)) revert PaymasterIdCannotBeZero();
        if (msg.value == 0) revert DepositeCannotBeZero();
        
        paymasterIdBalances[paymasterId] = paymasterIdBalances[paymasterId] + msg.value;

        emit GasDeposited(paymasterId, msg.value);
    }

    /// @dev Override the default implementation
    function deposit() public payable override {
        revert("use depositeFor instead");
    }

    /// @dev Withdraws the specified amount of gas tokens from the paymaster's balance and transfers them to the specified address
    /// @param withdrawAddress The address to which the gas tokens should be transferred
    /// @param amount The amount of gas tokens to withdraw
    function withdrawTo(address payable withdrawAddress, uint256 amount) public override nonReentrant {
        if (withdrawAddress == address(0)) revert CanNotWithdrawToZeroAddress();
        uint256 currectBalance = paymasterIdBalances[msg.sender];
        if (amount > currectBalance) revert InsufficientBalance(amount, currectBalance);
        
        paymasterIdBalances[msg.sender] = paymasterIdBalances[msg.sender] - amount;
        entryPoint.withdrawTo(withdrawAddress, amount);

        emit GasWithdraw(msg.sender, withdrawAddress, amount);
    }

    /// @dev Set a new verifying signer address
    /// @param newVerifyingSigner The new address to be set as the verifying signer
    function setSigner(address newVerifyingSigner) external onlyOwner {
        if (newVerifyingSigner == address(0)) revert VerifyingSignerCannotBeZero();
        address oldSigner = verifyingSigner;

        assembly {
            sstore(verifyingSigner.slot, newVerifyingSigner)
        }

        emit VerifyingSingerChanged(oldSigner, newVerifyingSigner, msg.sender);
    }

    /// @dev Set a new unaccountedEPGasOverhead
    function setUnaccountedEPGasOverhead(uint256 newValue) external onlyOwner {
        uint256 oldValue = unaccountedEPGasOverhead;
        unaccountedEPGasOverhead = newValue;
        emit EPGasOverheadChanged(oldValue, newValue);
    }

    /// @dev This method is called by the off-chain service, to sign the request.
    ///      It is called on-chain from the validatePaymasterUserOp, to validate the signature.
    /// @notice That this signature covers all fields of the UserOperation, except the "paymasterAndData",
    ///      which will carry the signature itself.
    /// @return hash we're going to sign off-chain (and validate on-chain)
    function getHash(
        UserOperation calldata userOp,
        address paymasterId
    ) public view returns (bytes32) {
        // can't use userOp.hash(), since it contains also the paymasterAndData itself.
        address sender = userOp.getSender();
        return
            keccak256(
                abi.encode(
                    sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    block.chainid,
                    address(this),
                    paymasterId
                )
            );
    }

    /// @dev Verify that an external signer signed the paymaster data of a user operation.
    /// The paymaster data is expected to be the paymaster and a signature over the entire request parameters.
    /// @param userOp The UserOperation struct that represents the current user operation.
    /// @param userOpHash The hash of the UserOperation struct.
    /// @param requiredPreFund The required amount of pre-funding for the paymaster.
    /// @return context A context string returned by the entry point after successful validation.
    /// @return validationData An integer returned by the entry point after successful validation.
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    ) internal override returns (bytes memory context, uint256 validationData){
        PaymasterData memory paymasterData = userOp._decodePaymasterData();
        console.log("_decodePaymasterData"); //
        bytes32 hash = getHash(userOp, paymasterData.paymasterId);
        uint256 sigLength = paymasterData.singnatureLength;
        // we only "require" it here so that the revert reason on invalid signature will be of "VerifyingPaymaster", and not "ECDSA"
        if (sigLength != 65) revert InvalidPaymasterSignatureLength(sigLength);
        // don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (
            verifyingSigner !=
            hash.toEthSignedMessageHash().recover(paymasterData.signature)
        ) {
            // empty context and sigTimeRange 1
            return ("", 1);
        }

        if (requiredPreFund > paymasterIdBalances[paymasterData.paymasterId])
            revert InsufficientBalance(
                requiredPreFund,
                paymasterIdBalances[paymasterData.paymasterId]
            );
        
        return (userOp.paymasterContext(paymasterData, userOp.gasPrice()), 0);
    }

    /// @dev Executes the paymaster's payment conditions
    /// @param mode tells whether the op succeeded, reverted, or if the op succeeded but cause the postOp to revert
    /// @param context payment conditions signed by the paymaster in `validatePaymasterUserOp`
    /// @param actualGasCost amount to be paid to the entry point in wei
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal virtual override {
        PaymasterContext memory data = context._decodePaymasterContext();
        address extractedPaymasterId = data.paymasterId;
        uint256 balToDeduct = actualGasCost +
            unaccountedEPGasOverhead * data.gasPrice;
        paymasterIdBalances[extractedPaymasterId] = paymasterIdBalances[extractedPaymasterId] - balToDeduct;

        emit GasBalanceDeducted(extractedPaymasterId, balToDeduct);
    }
}