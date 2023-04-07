// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

contract MockSignatureChecker {
    using SignatureChecker for address;

    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) public view returns (bool) {
        return signer.isValidSignatureNow(hash, signature);
    }
}