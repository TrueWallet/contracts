// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {ISocialRecoveryModule, GuardianInfo, PendingGuardianEntry, RecoveryEntry} from "./ISocialRecoveryModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {AddressLinkedList} from "src/libraries/AddressLinkedList.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {IWallet} from "src/wallet/IWallet.sol";

contract SocialRecoveryModule is ISocialRecoveryModule, BaseModule {
    using AddressLinkedList for mapping(address => address);
    // using TypeConversion for address;

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
    bytes4 private constant _FUNC_TRANSFER_OWNERSHIP = bytes4(keccak256("transferOwnership(address)"));

    mapping(address => uint256) walletRecoveryNonce;
    mapping(address => uint256) walletInitSeed;

    mapping(address => GuardianInfo) internal walletGuardian;
    mapping(address => PendingGuardianEntry) internal walletPendingGuardian;

    mapping(address => mapping(bytes32 => uint256)) approvedRecords;
    mapping(address => RecoveryEntry) recoveryEntries;

    uint128 private __seed;

    modifier onlyAuthorized(address _wallet) {
        if (!IWallet(_wallet).isAuthorizedModule(address(this))) {
            revert SocialRecovery__Unauthorized();
        }
        _;
    }

    modifier whenRecovery(address _wallet) {
        if (recoveryEntries[_wallet].executeAfter == 0) {
            revert SocialRecovery__NoOngoingRecovery();
        }
        _;
    }

    modifier whenNotRecovery(address _wallet) {
        if (recoveryEntries[_wallet].executeAfter > 0) {
            revert SocialRecovery__OngoingRecovery();
        }
        _;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

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
    function encodeSocialRecoveryData(address _wallet, address[] memory _newOwners, uint256 _nonce)
        public
        view
        returns (bytes memory)
    {
        bytes32 recoveryHash =
            keccak256(abi.encode(_SOCIAL_RECOVERY_TYPEHASH, _wallet, keccak256(abi.encodePacked(_newOwners)), _nonce));
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), recoveryHash);
    }

    function getSocialRecoveryHash(address _wallet, address[] memory _newOwners, uint256 _nonce)
        public
        view
        returns (bytes32)
    {
        return keccak256(encodeSocialRecoveryData(_wallet, _newOwners, _nonce));
    }

    function _newSeed() private returns (uint128) {
        __seed++;
        return __seed;
    }

    function inited(address _wallet) internal view override returns (bool) {
        return walletInitSeed[_wallet] != 0;
    }

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

    function _deInit() internal override {
        address _sender = sender();
        walletInitSeed[_sender] = 0;
        delete walletGuardian[_sender];
        delete walletPendingGuardian[_sender];
        delete recoveryEntries[_sender];
    }

    function _processGuardianUpdatesIfDue(address _wallet) private {
        if (
            walletPendingGuardian[_wallet].pendingUntil > 0
                && walletPendingGuardian[_wallet].pendingUntil > block.timestamp
        ) {
            if (walletPendingGuardian[_wallet].guardianHash != bytes32(0)) {
                // if set anonymous guardian, clear onchain guardian
                walletGuardian[_wallet].guardians.clear();
                walletGuardian[_wallet].guardianHash = walletPendingGuardian[_wallet].guardianHash;
            } else if (walletPendingGuardian[_wallet].guardians.length > 0) {
                // if set onchain guardian, clear anonymous guardian
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

            delete walletPendingGuardian[_wallet];
        }
    }

    modifier processGuardianUpdatesIfDue(address _wallet) {
        _processGuardianUpdatesIfDue(_wallet);
        _;
    }

    function guardiansCount(address _wallet) public view returns (uint256) {
        return walletGuardian[_wallet].guardians.size();
    }

    function getGuardians(address _wallet) public view returns (address[] memory) {
        uint256 guardianSize = walletGuardian[_wallet].guardians.size();
        return walletGuardian[_wallet].guardians.list(AddressLinkedList.SENTINEL_ADDRESS, guardianSize);
    }

    function getGuardiansHash(address _wallet) public view returns (bytes32) {
        return walletGuardian[_wallet].guardianHash;
    }

    function isGuardian(address _wallet, address _guardian) public view returns (bool) {
        return walletGuardian[_wallet].guardians.isExist(_guardian);
    }

    function threshold(address _wallet) public view returns (uint256) {
        return walletGuardian[_wallet].threshold;
    }

    function nonce(address _wallet) public view returns (uint256) {
        return walletRecoveryNonce[_wallet];
    }

    function pendingGuarian(address _wallet) public view returns (uint256, uint256, bytes32, address[] memory) {
        return (
            walletPendingGuardian[_wallet].pendingUntil,
            walletPendingGuardian[_wallet].threshold,
            walletPendingGuardian[_wallet].guardianHash,
            walletPendingGuardian[_wallet].guardians
        );
    }

    function updateGuardians(address[] calldata _guardians, uint256 _threshold, bytes32 _guardianHash)
        external
        onlyAuthorized(sender())
        whenNotRecovery(sender())
        processGuardianUpdatesIfDue(sender())
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

    // the wallet itself or an existing guardian for that wallet
    function cancelSetGuardians(address _wallet) external onlyAuthorized(_wallet) {
        if (walletPendingGuardian[_wallet].pendingUntil == 0) {
            revert SocialRecovery__NoPendingGuardian();
        }
        if (_wallet != sender()) {
            if (!isGuardian(_wallet, sender())) {
                revert SocialRecovery__Unauthorized();
            }
        }

        _processGuardianUpdatesIfDue(_wallet);

        delete walletPendingGuardian[_wallet]; // 2 times delete
    }

    function revealAnonymousGuardians(address _wallet, address[] calldata _guardians, uint256 _salt)
        public
        onlyAuthorized(_wallet)
        processGuardianUpdatesIfDue(_wallet)
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
        // 1. check hash
        bytes32 guardianHash = getAnonymousGuardianHash(_guardians, _salt);
        if (guardianHash != walletGuardian[_wallet].guardianHash) {
            revert SocialRecovery__InvalidGuardianHash();
        }
        // 2. update guardian list in storage
        for (uint256 i; i < _guardians.length;) {
            walletGuardian[_wallet].guardians.add(_guardians[i]);
            unchecked {
                i++;
            }
        }
        // 3. clear anonymous guardians hash
        walletGuardian[_wallet].guardianHash = bytes32(0);

        emit AnonymousGuardianRevealed(_wallet, _guardians, guardianHash);
    }

    function getAnonymousGuardianHash(address[] calldata _guardians, uint256 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_guardians, _salt));
    }

    function approveRecovery(address _wallet, address[] memory _newOwners) external onlyAuthorized(_wallet) {
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

        // in case this is the first approval => initiate recovery request
        if (recoveryEntries[_wallet].executeAfter == 0) {
            _pendingRecovery(_wallet, _newOwners, _nonce);
        }
    }

    function _pendingRecovery(address _wallet, address[] memory _newOwners, uint256 _nonce) private {
        // new pending recovery
        uint256 executeAfter = block.timestamp + 2 days;
        recoveryEntries[_wallet] = RecoveryEntry(_newOwners, executeAfter, _nonce);
        walletRecoveryNonce[_wallet]++;
        emit PendingRecovery(_wallet, _newOwners, _nonce, executeAfter);
    }

    function executeRecovery(address _wallet) external whenRecovery(_wallet) onlyAuthorized(_wallet) {
        // guardians should be revealed before execution - covered by whenRecovery(_wallet)
        if ((walletGuardian[_wallet].guardianHash != 0) && (walletGuardian[_wallet].guardians.size() > 0)) {
            revert SocialRecovery__AnonymousGuardianNotRevealed();
        }
        RecoveryEntry memory request = recoveryEntries[_wallet];
        // request.executeAfter != 0 -> whenRecovery(_wallet)
        // check RecoveryEntry.executeUntil > block.timestamp
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
        wallet.transferOwnership(_newOwners[0]);
        // wallet.resetOwners(_newOwners);

        emit SocialRecoveryExecuted(_wallet, _newOwners);
    }

    /// @notice Retrieves the wallet's current ongoing recovery request.
    /// @param _wallet The target wallet.
    /// @return request The wallet's current recovery request
    function getRecoveryEntry(address _wallet) public view returns (RecoveryEntry memory) {
        return recoveryEntries[_wallet];
    }

    function getRecoveryApprovals(address _wallet, address[] memory _newOwners)
        public
        view
        returns (uint256 approvalCount)
    {
        // uint256 _nonce = nonce(_wallet);
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

    function hasGuardianApproved(address _guardian, address _wallet, address[] calldata _newOwners)
        public
        view
        returns (uint256)
    {
        uint256 _nonce = recoveryEntries[_wallet].nonce;
        bytes32 recoveryHash = getSocialRecoveryHash(_wallet, _newOwners, _nonce);
        return approvedRecords[_guardian][recoveryHash];
    }

    function cancelRecovery(address wallet) external {}

    // guardians should be revealed
    function batchApproveRecovery(
        address wallet,
        address[] calldata newOwner,
        uint256 signatureCount,
        bytes memory signatures
    ) external {}

    function requiredFunctions() external pure returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](3);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        functions[2] = _FUNC_TRANSFER_OWNERSHIP;
        return functions;
    }
}
