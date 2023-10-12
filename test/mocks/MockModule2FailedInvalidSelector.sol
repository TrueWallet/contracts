// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "src/modules/BaseModule.sol";

contract MockModule2FailedInvalidSelector is BaseModule {
    mapping(address => bool) public isInit;
    mapping(address => uint32) public walletInitData;

    event initEvent(address wallet);
    event deInitEvent(address wallet);

    bytes4 constant _function = bytes4(keccak256("transferETH(address,uint256)"));

    function requiredFunctions() external pure override returns (bytes4[] memory) {
        bytes4[] memory _requiredFunctions = new bytes4[](4); //[0x7b1a4909, 0xae9411ab, 0x00000000, 0x00000000] "InvalidSelector()"
        _requiredFunctions[0] = _function;
        _requiredFunctions[1] = IModuleManager.executeFromModule.selector;
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

    function transferETH(address target, address to, uint256 amount) external {
        require(inited(target));
        (bool ok, bytes memory res) = target.call{value: 0}(abi.encodeWithSelector(_function, to, amount));
        require(ok, string(res));
    }
}
