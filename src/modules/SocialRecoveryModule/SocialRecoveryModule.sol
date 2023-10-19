// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.19;

import {ISocialRecoveryModule, GuardianInfo, PendingGuardianEntry, RecoveryEntry} from "./ISocialRecoveryModule.sol";
import {BaseModule} from "../BaseModule.sol";
import {AddressLinkedList} from "src/libraries/AddressLinkedList.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {IWallet} from "src/wallet/IWallet.sol";

import "lib/forge-std/src/console.sol";


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


    function encodeSocialRecoveryData(address _wallet, address[] calldata _newOwners, uint256 _nonce)
        public
        view
        returns (bytes memory)
    {
        bytes32 recoveryHash =
            keccak256(abi.encode(_SOCIAL_RECOVERY_TYPEHASH, _wallet, keccak256(abi.encodePacked(_newOwners)), _nonce));
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), recoveryHash);
    }

    function getSocialRecoveryHash(address _wallet, address[] calldata _newOwners, uint256 _nonce)
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
            if (_threshold == 0) { // TBC _guardianHash count
                revert SocialRecovery__InvalidThreshold();
            }
            if (_guardianHash == bytes32(0)) {
                revert SocialRecovery__AnonymousGuardianConfigError();
            }
        }
        // console.log(_guardians.length);
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

    function _checkLatestGuardian(address _wallet) private {
        if (
            walletPendingGuardian[_wallet].pendingUntil > 0
            && walletPendingGuardian[_wallet].pendingUntil > block.timestamp
        ) {
            if (walletPendingGuardian[_wallet].guardianHash != bytes32(0)) {
                // if set anonomous guardian, clear onchain guardian
                walletGuardian[_wallet].guardians.clear();
                walletGuardian[_wallet].guardianHash = walletPendingGuardian[_wallet].guardianHash;
            } else if (walletPendingGuardian[_wallet].guardians.length > 0) {
                // if set onchain guardian, clear anonomous guardian
                walletGuardian[_wallet].guardianHash = bytes32(0);
                walletGuardian[_wallet].guardians.clear();
                for (uint i; i < walletPendingGuardian[_wallet].guardians.length;) {
                    walletGuardian[_wallet].guardians.add(walletPendingGuardian[_wallet].guardians[i]);
                    unchecked {
                        i++;
                    }
                }
            }

            delete walletPendingGuardian[_wallet];
        }
    }

    modifier checkLatestGuardian(address _wallet) {
        _checkLatestGuardian(_wallet);
        _;
    }

    function guardiansCount(address _wallet) public view returns (uint256) {
        return walletGuardian[_wallet].guardians.size();
    }

    function getGuardians(address _wallet) public view returns (address[] memory) {
        uint256 guardianSize = walletGuardian[_wallet].guardians.size();
        return walletGuardian[_wallet].guardians.list(AddressLinkedList.SENTINEL_ADDRESS, guardianSize);
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

    function updateGuardians(address[] calldata _guardians, uint256 _threshold, bytes32 _guardianHash)
        external
        onlyAuthorized(sender())
        whenNotRecovery(sender())
        checkLatestGuardian(sender())
    {
        address wallet = sender();
        if (_guardians.length > 0) {
            if (_guardianHash != bytes32(0)) {
                revert SocialRecovery__OnchainGuardianConfigError();
            }
        }
        if (_guardians.length == 0) {
            if (_guardianHash == bytes32(0)) {
                revert SocialRecovery__AnonymousGuardianConfigError();
            }
        }
        if (_threshold == 0 || _threshold > _guardians.length) {
            revert SocialRecovery__InvalidThreshold();
        }
        PendingGuardianEntry memory pendingEntry;
        pendingEntry.pendingUntil = block.timestamp + 2 days;
        pendingEntry.guardians = _guardians;

        pendingEntry.guardianHash = _guardianHash;
        walletPendingGuardian[wallet] = pendingEntry;
    }

    function cancelGuardians(address wallet) external {} // owner or guardian

    function approveRecovery(address wallet, address[] calldata newOwners) external {}

    function batchApproveRecovery(
        address wallet,
        address[] calldata newOwner,
        uint256 signatureCount,
        bytes memory signatures
    ) external {}

    function executeRecovery(address wallet) external {}

    function cancelRecovery(address wallet) external {}

    function requiredFunctions() external pure returns (bytes4[] memory) {
        bytes4[] memory functions = new bytes4[](2);
        functions[0] = _FUNC_RESET_OWNER;
        functions[1] = _FUNC_RESET_OWNERS;
        return functions;
    }

}
