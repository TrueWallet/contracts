// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./MockBaseModuleFailed.sol";
import "src/interfaces/IWallet.sol";

contract MockModuleFailedNotSupportInterface is MockBaseModuleFailed {
    mapping(address => bool) public isInit;
    mapping(address => uint32) public walletInitData;

    event initEvent(address wallet);
    event deInitEvent(address wallet);

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        // transferETH(address,uint256)
        bytes4[] memory _requiredFunctions = new bytes4[](1);
        _requiredFunctions[0] = bytes4(keccak256("transferETH(address,uint256)"));
        return _requiredFunctions;
    }

    function inited(address wallet) internal view override returns (bool) {
        return isInit[wallet];
    }

    function _init(bytes calldata data) internal override {
        (uint32 value) = abi.decode(data, (uint32));
        walletInitData[sender()] = value;
        isInit[sender()] = true;
        emit initEvent(sender());
    }

    function _deInit() internal override {
        isInit[sender()] = false;
        emit deInitEvent(sender());
    }

    function transferETH(address target, address to, uint256 amount) external pure {
        (target, to, amount);
    }
}
