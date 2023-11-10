// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {ISocialRecoveryModule, GuardianInfo, PendingGuardianEntry, RecoveryEntry} from "./ISocialRecoveryModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {AddressLinkedList} from "src/libraries/AddressLinkedList.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {IWallet} from "src/wallet/IWallet.sol";

/**
 * @title SocialRecoveryModule
 * @dev Contract module that allows a group of guardians to collectively recover a wallet.
 * This is intended for scenarios where the wallet owner is unable to access their wallet.
 * The module adheres to the ISocialRecoveryModule interface and extends BaseModule for shared functionality.
 */
contract SocialRecoveryModule is ISocialRecoveryModule, BaseModule {
    using AddressLinkedList for mapping(address => address);

    string public constant NAME = "True Social Recovery Module";
    string public constant VERSION = "0.0.1";

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _DOMAIN_SEPARATOR_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // keccak256("SocialRecovery(address wallet,address[] newOwners,uint256 nonce)");
    bytes32 private constant _SOCIAL_RECOVERY_TYPEHASH =
        0x333ef7ecc7b8a82065578df0879cefc36c32344d49afdf1e0370a60babe64feb;

    bytes4 private constant _FUNC_RESET_OWNER = bytes4(keccak256("resetOwner(address)"));
    bytes4 private constant _FUNC_RESET_OWNERS = bytes4(keccak256("resetOwners(address[])"));

    mapping(address => uint256) walletRecoveryNonce;
    mapping(address => uint256) walletInitSeed;

    mapping(address => GuardianInfo) internal walletGuardian;
    mapping(address => PendingGuardianEntry) internal walletPendingGuardian;

    mapping(address => mapping(bytes32 => uint256)) approvedRecords;
    mapping(address => RecoveryEntry) recoveryEntries;

    uint128 private __seed;

    /// @notice Throws if the sender is not the wallet itself that authorized this module.
    modifier authorized(address _wallet) {
        if (!IWallet(_wallet).isAuthorizedModule(address(this))) {
            revert SocialRecovery__Unauthorized();
        }
        _;
    }

    /// @notice Throws if there is no ongoing recovery request.
    modifier whenRecovery(address _wallet) {
        if (recoveryEntries[_wallet].executeAfter == 0) {
            revert SocialRecovery__NoOngoingRecovery();
        }
        _;
    }

    /// @notice Throws if there is an ongoing recovery request.
    modifier whenNotRecovery(address _wallet) {
        if (recoveryEntries[_wallet].executeAfter > 0) {
            revert SocialRecovery__OngoingRecovery();
        }
        _;
    }

    /// @notice Modifier to check and apply pending guardian updates before executing a function.
    /// @param _wallet The address of the wallet to check.
    modifier checkPendingGuardian(address _wallet) {
        _checkApplyGuardianUpdate(_wallet);
        _;
    }

    /// @dev Internal function to initialize the wallet with guardians, threshold, and guardian hash.
    /// This can set up both on-chain and off-chain (anonymous) guardians.
    /// @param data Encoded data containing guardians, threshold, and guardian hash.
    function _init(bytes calldata data) internal override {
        (address[] memory _guardians, uint256 _threshold, bytes32 _guardianHash) =
            abi.decode(data, (address[], uint256, bytes32));
        address _sender = sender();
        if (_guardians.length > 0) {
            if (_threshold == 0 || _threshold > _guardians.length) {
                revert SocialRecovery__InvalidThreshold();
            }
            if (_guardianHash != bytes32(0)) {
                revert SocialRecovery__OnchainGuardianConfigError();
            }
        }
        if (_guardians.length == 0) {
            if (_threshold == 0) {
                // TBC _guardianHash count
                revert SocialRecovery__InvalidThreshold();
            }
            if (_guardianHash == bytes32(0)) {
                revert SocialRecovery__AnonymousGuardianConfigError();
            }
        }
        for (uint256 i; i < _guardians.length;) {
            walletGuardian[_sender].guardians.add(_guardians[i]);
            unchecked {
                i++;
            }
        }
        walletGuardian[_sender].guardianHash = _guardianHash;
        walletGuardian[_sender].threshold = _threshold;
        walletInitSeed[_sender] = _newSeed();
    }

    /// @dev Internal function to de-initialize a wallet. This clears all recovery settings.
    function _deInit() internal override {
        address _sender = sender();
        walletInitSeed[_sender] = 0;
        delete walletGuardian[_sender];
        delete walletPendingGuardian[_sender];
        delete recoveryEntries[_sender];
    }

    /// @notice Checks if a wallet is initialized.
    /// @param _wallet The address of the wallet to check.
    /// @return bool True if the wallet is initialized, false otherwise.
    function isInit(address _wallet) external view returns (bool) {
        return inited(_wallet);
    }

    // TODO TBC: addGuardians to existing list
    // _checkApplyGuardianUpdate allows only new list of guardians addresses, not previous
    /// @notice External function to process any pending guardian updates for a wallet.
    /// @param _wallet The address of the wallet for which to process guardian updates.
    function processGuardianUpdates(address _wallet) external authorized(sender()) {
        _checkApplyGuardianUpdate(_wallet);
    }

    /// @dev Internal function to apply pending guardian updates after the delay period.
    /// @param _wallet The address of the wallet to update guardians for.
    function _checkApplyGuardianUpdate(address _wallet) private {
        if (
            walletPendingGuardian[_wallet].pendingUntil > 0
                && walletPendingGuardian[_wallet].pendingUntil > block.timestamp
        ) {
            if (walletPendingGuardian[_wallet].guardianHash != bytes32(0)) {
                // If set anonymous guardian, clear onchain guardian
                walletGuardian[_wallet].guardians.clear();
                walletGuardian[_wallet].guardianHash = walletPendingGuardian[_wallet].guardianHash;
            } else if (walletPendingGuardian[_wallet].guardians.length > 0) {
                // If set onchain guardian, clear anonymous guardian
                walletGuardian[_wallet].guardianHash = bytes32(0);
                walletGuardian[_wallet].guardians.clear();
                for (uint256 i; i < walletPendingGuardian[_wallet].guardians.length;) {
                    if (walletPendingGuardian[_wallet].guardians[i] != address(0)) {
                        walletGuardian[_wallet].guardians.add(walletPendingGuardian[_wallet].guardians[i]);
                    }
                    unchecked {
                        i++;
                    }
                }
            }
            walletGuardian[_wallet].threshold = walletPendingGuardian[_wallet].threshold; //
            delete walletPendingGuardian[_wallet];
        }
    }

    /// @notice Submits a request to update the guardians for the caller's wallet.
    /// This update is pending for a certain delay before being applied.
    /// @param _guardians The list of new guardians to be set.
    /// @param _threshold The new threshold for guardian consensus.
    /// @param _guardianHash The new guardian hash to be used for off-chain guardians.
    function updatePendingGuardians(address[] calldata _guardians, uint256 _threshold, bytes32 _guardianHash)
        external
        authorized(sender())
        whenNotRecovery(sender())
        checkPendingGuardian(sender())
    {
        address wallet = sender();
        if (_guardians.length > 0) {
            if (_threshold == 0 || _threshold > _guardians.length) {
                revert SocialRecovery__InvalidThreshold();
            }
            if (_guardianHash != bytes32(0)) {
                revert SocialRecovery__OnchainGuardianConfigError();
            }
        }
        if (_guardians.length == 0) {
            if (_threshold == 0) {
                revert SocialRecovery__InvalidThreshold();
            }
            if (_guardianHash == bytes32(0)) {
                revert SocialRecovery__AnonymousGuardianConfigError();
            }
        }
        PendingGuardianEntry memory pendingEntry;
        pendingEntry.pendingUntil = block.timestamp + 2 days;
        pendingEntry.threshold = _threshold;
        pendingEntry.guardians = _guardians;
        pendingEntry.guardianHash = _guardianHash;
        walletPendingGuardian[wallet] = pendingEntry;
    }

    /// @notice Allows a wallet or its current guardian to cancel a pending guardian update.
    /// @param _wallet The address of the wallet for which the pending update is to be cancelled.
    /// @dev Reverts if there is no pending guardian update or if the caller is not authorized.
    /// @dev Applies any pending guardian update before proceeding to cancel the next one.
    function cancelSetGuardians(address _wallet) external authorized(_wallet) {
        if (walletPendingGuardian[_wallet].pendingUntil == 0) {
            revert SocialRecovery__NoPendingGuardian();
        }
        if (_wallet != sender()) {
            if (!isGuardian(_wallet, sender())) {
                revert SocialRecovery__Unauthorized();
            }
        }

        _checkApplyGuardianUpdate(_wallet); // TODO TBC to remove

        delete walletPendingGuardian[_wallet]; // 2 times delete
    }

    /// @notice Reveal the anonymous guardians of a wallet.
    /// @dev Reverts if the list of guardians is not sorted or the guardian hash doesn't match.
    /// @param _wallet The address of the wallet for which to reveal guardians.
    /// @param _guardians The array of guardian addresses.
    /// @param _salt The salt used to hash the anonymous guardian list.
    function revealAnonymousGuardians(address _wallet, address[] calldata _guardians, uint256 _salt)
        public
        authorized(_wallet)
        checkPendingGuardian(_wallet)
    {
        if (_wallet != sender()) {
            if (!isGuardian(_wallet, sender())) {
                revert SocialRecovery__Unauthorized();
            }
        }
        address lastGuardian = address(0);
        address currentGuardian;
        for (uint256 i; i < _guardians.length;) {
            currentGuardian = _guardians[i];
            if (currentGuardian <= lastGuardian) revert SocialRecovery__InvalidGuardianList();
            lastGuardian = currentGuardian;
            unchecked {
                i++;
            }
        }
        // 1. Check hash
        bytes32 guardianHash = getAnonymousGuardianHash(_guardians, _salt);
        if (guardianHash != walletGuardian[_wallet].guardianHash) {
            revert SocialRecovery__InvalidGuardianHash();
        }
        // 2. Update guardian list in storage
        for (uint256 i; i < _guardians.length;) {
            walletGuardian[_wallet].guardians.add(_guardians[i]);
            unchecked {
                i++;
            }
        }
        // 3. Clear anonymous guardians hash
        walletGuardian[_wallet].guardianHash = bytes32(0);

        emit AnonymousGuardianRevealed(_wallet, _guardians, guardianHash);
    }

    /// @notice Approve a wallet recovery process initiated by guardians.
    /// @dev Reverts if no new owners are provided or the caller is not authorized.
    /// @param _wallet The address of the wallet undergoing recovery.
    /// @param _newOwners The proposed new array of owner addresses.
    function approveRecovery(address _wallet, address[] memory _newOwners) external authorized(_wallet) {
        if (_newOwners.length == 0) revert SocialRecovery__OwnersEmpty();
        if (!isGuardian(_wallet, sender())) {
            revert SocialRecovery__Unauthorized();
        }
        uint256 _nonce = nonce(_wallet);
        if (recoveryEntries[_wallet].executeAfter > 0) {
            _nonce = recoveryEntries[_wallet].nonce;
        }
        bytes32 recoveryHash = getSocialRecoveryHash(_wallet, _newOwners, _nonce);
        approvedRecords[sender()][recoveryHash] = 1;
        emit ApproveRecovery(_wallet, sender(), recoveryHash);

        // In case this is the first approval => initiate recovery request
        if (recoveryEntries[_wallet].executeAfter == 0) {
            _pendingRecovery(_wallet, _newOwners, _nonce);
        }
    }

    /// @notice Initiates a new pending recovery process for a given wallet, setting new owners and a future timestamp for execution.
    /// @param _wallet The address of the wallet undergoing recovery.
    /// @param _newOwners An array of addresses that will be the new owners of the wallet after recovery.
    /// @param _nonce The nonce associated with the recovery process, ensuring the recovery action is unique.
    function _pendingRecovery(address _wallet, address[] memory _newOwners, uint256 _nonce) private {
        uint256 executeAfter = block.timestamp + 2 days;
        recoveryEntries[_wallet] = RecoveryEntry(_newOwners, executeAfter, _nonce);
        walletRecoveryNonce[_wallet]++;
        emit PendingRecovery(_wallet, _newOwners, _nonce, executeAfter);
    }

    /// @notice Executes a pending recovery operation if all conditions are met.
    /// @dev This function will revert if the guardian hash is set and there are guardians present, 
    /// if the recovery period is still pending, or if there are not enough guardian approvals.
    /// It delegates the actual execution to the `_executeRecovery` internal function.
    /// @param _wallet The address of the wallet for which to execute the recovery operation.
    function executeRecovery(address _wallet) external whenRecovery(_wallet) authorized(_wallet) {
        // guardians should be revealed before execution - covered by whenRecovery(_wallet)
        if ((walletGuardian[_wallet].guardianHash != 0) && (walletGuardian[_wallet].guardians.size() > 0)) {
            revert SocialRecovery__AnonymousGuardianNotRevealed();
        }
        RecoveryEntry memory request = recoveryEntries[_wallet];
        if (block.timestamp < request.executeAfter) {
            revert SocialRecovery__RecoveryPeriodStillPending();
        }
        uint256 guardiansThreshold = threshold(_wallet);
        uint256 _approvalCount = getRecoveryApprovals(_wallet, request.newOwners);
        if (_approvalCount < guardiansThreshold) {
            revert SocialRecovery__NotEnoughApprovals();
        }
        _executeRecovery(_wallet, request.newOwners);
    }

    /// @dev Internal function to execute recovery, updating the nonce and transferring ownership.
    /// @param _wallet The address of the wallet undergoing recovery.
    /// @param _newOwners The array of new owner addresses to set for the wallet.
    function _executeRecovery(address _wallet, address[] memory _newOwners) private {
        if (_newOwners.length == 0) revert SocialRecovery__OwnersEmpty();
        // check and update nonce
        if (recoveryEntries[_wallet].nonce == nonce(_wallet)) {
            walletRecoveryNonce[_wallet]++;
        }
        // delete RecoveryEntry
        delete recoveryEntries[_wallet];

        IWallet wallet = IWallet(payable(_wallet));
        // update owners
        wallet.resetOwners(_newOwners);

        emit SocialRecoveryExecuted(_wallet, _newOwners);
    }

    /// @notice Cancels the ongoing recovery process for a wallet.
    /// @dev Can only be called by the wallet itself, reverts if the caller is not the wallet.
    /// @param _wallet The address of the wallet for which to cancel recovery.
    function cancelRecovery(address _wallet) external authorized(_wallet) whenRecovery(_wallet) {
        if (msg.sender != _wallet) {
            revert SocialRecovery__OnlyWalletItselfCanCancelRecovery();
        }
        emit SocialRecoveryCanceled(_wallet, recoveryEntries[_wallet].nonce);
        delete recoveryEntries[_wallet];
    }

    /// @notice Batch approval process for wallet recovery with signatures from guardians.
    /// @dev Handles both pending and immediate recovery executions based on signatures count.
    /// @param _wallet The address of the wallet undergoing recovery.
    /// @param _newOwners The proposed new array of owner addresses.
    /// @param _signatureCount The number of signatures provided.
    /// @param _signatures Concatenated signatures from the guardians.
    function batchApproveRecovery(
        address _wallet,
        address[] calldata _newOwners,
        uint256 _signatureCount,
        bytes memory _signatures // guardians signatures arranged based on the sorted addresses.
    ) external authorized(_wallet) {
        // Apply & clear pending guardians settings
        _checkApplyGuardianUpdate(_wallet);
        // Check that guardians revealed
        if ((walletGuardian[_wallet].guardianHash != 0) || (walletGuardian[_wallet].guardians.size() == 0)) {
            revert SocialRecovery__AnonymousGuardianNotRevealed();
        }
        if (_newOwners.length == 0) revert SocialRecovery__OwnersEmpty();
        uint256 _nonce = nonce(_wallet);
        bytes32 recoveryHash = getSocialRecoveryHash(_wallet, _newOwners, _nonce);
        // Validate signatures & guardians
        checkNSignatures(_wallet, recoveryHash, _signatureCount, _signatures);
        // If (numConfirmed == numGuardian) => execute recovery
        if (_signatureCount == walletGuardian[_wallet].guardians.size()) {
            _executeRecovery(_wallet, _newOwners);
        }
        // If (numConfirmed < threshold || _signatureCount > threshold) => pending recovery
        if (
            (_signatureCount < threshold(_wallet))
                || ((_signatureCount > threshold(_wallet)) && (_signatureCount != walletGuardian[_wallet].guardians.size()))
        ) {
            _pendingRecovery(_wallet, _newOwners, _nonce);
        }
        emit BatchApproveRecovery(_wallet, _newOwners, _signatureCount, _signatures, recoveryHash);
    }

    /// @dev Increment and get the new seed for wallet initialization.
    /// The seed is used to uniquely identify the wallet's initialization state.
    /// @return uint128 The incremented seed value.
    function _newSeed() private returns (uint128) {
        __seed++;
        return __seed;
    }

    /// @dev Internal function to check if a wallet has been initialized.
    /// @param _wallet The address of the wallet to check.
    /// @return bool True if the wallet has a non-zero initialization seed, indicating it's been initialized.
    function inited(address _wallet) internal view override returns (bool) {
        return walletInitSeed[_wallet] != 0;
    }

    /// @notice Generates a hash of the guardians.
    /// @dev This hash is used to compare against the stored hash for validation.
    /// @param _guardians Array of guardians' addresses.
    /// @param _salt Salt value.
    /// @return The calculated keccak256 hash of the encoded guardians and salt.
    function getAnonymousGuardianHash(address[] calldata _guardians, uint256 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_guardians, _salt));
    }

    /// @notice Retrieves the wallet's current ongoing recovery request.
    /// @param _wallet The target wallet.
    /// @return request The wallet's current recovery request
    function getRecoveryEntry(address _wallet) public view returns (RecoveryEntry memory) {
        return recoveryEntries[_wallet];
    }

    /// @notice Retrieves the guardian approval count for this particular recovery request at current nonce.
    /// @param _wallet The target wallet.
    /// @param _newOwners The new owners' addressess.
    /// @return approvalCount The wallet's current recovery request
    function getRecoveryApprovals(address _wallet, address[] memory _newOwners)
        public
        view
        returns (uint256 approvalCount)
    {
        uint256 _nonce = recoveryEntries[_wallet].nonce;
        bytes32 recoveryHash = getSocialRecoveryHash(_wallet, _newOwners, _nonce);
        address[] memory guardians = getGuardians(_wallet);
        approvalCount = 0;
        //  mapping(address => mapping(bytes32 => uint256)) approvedRecords;
        for (uint256 i; i < guardians.length;) {
            if (approvedRecords[guardians[i]][recoveryHash] == 1) {
                approvalCount++;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Retrieves specific guardian approval status a particular recovery request at current nonce.
    /// @param _guardian The guardian.
    /// @param _wallet The target wallet.
    /// @param _newOwners The new owners' addressess.
    /// @return approvalCount The wallet's current recovery request
    function hasGuardianApproved(address _guardian, address _wallet, address[] calldata _newOwners)
        public
        view
        returns (uint256)
    {
        uint256 _nonce = recoveryEntries[_wallet].nonce;
        bytes32 recoveryHash = getSocialRecoveryHash(_wallet, _newOwners, _nonce);
        return approvedRecords[_guardian][recoveryHash];
    }

    /// @notice Counts the number of active guardians for a wallet.
    /// @param _wallet The target wallet.
    /// @return The number of active guardians for a wallet.
    function guardiansCount(address _wallet) public view returns (uint256) {
        return walletGuardian[_wallet].guardians.size();
    }

    /// @notice Get the active guardians for a wallet.
    /// @param _wallet The target wallet.
    /// @return the list of active guardians for a wallet.
    function getGuardians(address _wallet) public view returns (address[] memory) {
        uint256 guardianSize = walletGuardian[_wallet].guardians.size();
        return walletGuardian[_wallet].guardians.list(AddressLinkedList.SENTINEL_ADDRESS, guardianSize);
    }

    /// @dev Retrieves the wallet guardian hash.
    /// @param _wallet The target wallet.
    /// @return guardianHash.
    function getGuardiansHash(address _wallet) public view returns (bytes32) {
        return walletGuardian[_wallet].guardianHash;
    }

    /// @notice Checks if an address is a guardian for a wallet.
    /// @param _wallet The target wallet.
    /// @param _guardian The address to check.
    /// @return `true` if the address is a guardian for the wallet otherwise `false`.
    function isGuardian(address _wallet, address _guardian) public view returns (bool) {
        return walletGuardian[_wallet].guardians.isExist(_guardian);
    }

    /// @dev Retrieves the wallet threshold count.
    /// @param _wallet The target wallet.
    /// @return Threshold count.
    function threshold(address _wallet) public view returns (uint256) {
        return walletGuardian[_wallet].threshold;
    }

    /// @notice Get the module nonce for a wallet.
    /// @param _wallet The target wallet.
    /// @return The nonce for this wallet.
    function nonce(address _wallet) public view returns (uint256) {
        return walletRecoveryNonce[_wallet];
    }

    /// @notice Retrieves the pending guardian update details for a specified wallet.
    /// @param _wallet The address of the wallet for which to retrieve pending guardian details.
    /// @return pendingUntil The timestamp until which the update is pending.
    /// @return threshold The new threshold to be set after the update.
    /// @return guardianHash The new guardian hash to be set after the update.
    /// @return guardians The list of new guardians to be set after the update.
    function pendingGuarian(address _wallet) public view returns (uint256, uint256, bytes32, address[] memory) {
        return (
            walletPendingGuardian[_wallet].pendingUntil,
            walletPendingGuardian[_wallet].threshold,
            walletPendingGuardian[_wallet].guardianHash,
            walletPendingGuardian[_wallet].guardians
        );
    }

    /// @dev Referece from gnosis safe validation.
    /// @dev Validates a set of signatures for a given hash, ensuring they are from guardians.
    /// @param _wallet The address of the wallet to check signatures for.
    /// @param _dataHash The hash of the data the signatures should correspond to.
    /// @param _signatureCount The number of signatures to validate.
    /// @param _signatures Concatenated signatures to be split and checked.
    function checkNSignatures(address _wallet, bytes32 _dataHash, uint256 _signatureCount, bytes memory _signatures)
        public
    {
        // Check that the provided signature data is not too short
        require(_signatures.length >= _signatureCount * 65, "signatures too short");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _signatureCount; i++) {
            (v, r, s) = signatureSplit(_signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= _signatureCount * 65, "contract signatures too short");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s) + (32) <= _signatures.length, "contract signatures out of bounds");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(_signatures, s), 0x20))
                }
                require(uint256(s) + 32 + contractSignatureLen <= _signatures.length, "contract signature wrong offset");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(_signatures, s), 0x20)
                }
                (bool success, bytes memory result) = currentOwner.staticcall(
                    abi.encodeWithSelector(IERC1271.isValidSignature.selector, _dataHash, contractSignature)
                );
                require(
                    success && result.length == 32
                        && abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector),
                    "contract signature invalid"
                );
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(
                    msg.sender == currentOwner || approvedRecords[currentOwner][_dataHash] != 0,
                    "approve hash verify failed"
                );
            } else {
                // eip712 verify
                currentOwner = ecrecover(_dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && isGuardian(_wallet, currentOwner), "verify failed");
            lastOwner = currentOwner;
            // Hash approval
            approvedRecords[currentOwner][_dataHash] = 1;
        }
    }

    /// @dev Divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param _pos, to avoid out of bounds access on @param _signatures
    /// @param _pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param _signatures concatenated rsv signatures
    function signatureSplit(bytes memory _signatures, uint256 _pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, _pos)
            r := mload(add(_signatures, add(signaturePos, 0x20)))
            s := mload(add(_signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(_signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Calculates and returns the domain separator for the contract, which is used in EIP-712 typed data signing.
    /// @dev The domain separator is a unique hash for the domain that includes the contract's name, version, chain ID, and address,
    ///      used to prevent signature replay attacks across different domains.
    function domainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                _DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(abi.encodePacked(NAME)),
                keccak256(abi.encodePacked(VERSION)),
                getChainId(),
                this
            )
        );
    }

    // TODO memory vs calldata
    /// @dev Returns the bytes that are hashed to be signed by guardians.
    function encodeSocialRecoveryData(address _wallet, address[] memory _newOwners, uint256 _nonce)
        public
        view
        returns (bytes memory)
    {
        bytes32 recoveryHash =
            keccak256(abi.encode(_SOCIAL_RECOVERY_TYPEHASH, _wallet, keccak256(abi.encodePacked(_newOwners)), _nonce));
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), recoveryHash);
    }

    /// @dev Generates the recovery hash that should be signed by the guardian to authorize a recovery.
    function getSocialRecoveryHash(address _wallet, address[] memory _newOwners, uint256 _nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeSocialRecoveryData(_wallet, _newOwners, _nonce));
    }

    /// @notice Returns the required function selectors for the smart contract interface.
    /// @dev These function selectors are used for interface validation.
    /// @return selectors An array of bytes4 representing the required function signatures.
    function requiredFunctions() external pure returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        return functions;
    }
}
