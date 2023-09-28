// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "src/modules/BaseModule.sol";

contract MockModuleFailedEmptySelector is BaseModule {
    mapping(address => bool) public isInit;
    mapping(address => uint32) public walletInitData;

    event initEvent(address wallet);
    event deInitEvent(address wallet);

    // bytes4 public _function = bytes4(keccak256("transferETH(address,uint256)"));

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        // transferETH(address,uint256)
        bytes4[] memory _requiredFunctions = new bytes4[](1);
        // _requiredFunctions[0] = 0;
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
