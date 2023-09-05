// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {OFTV2} from "lz/token/oft/v2/OFTV2.sol";

/**
 * @author  0xAurelou
 * @title   ERC20 LayerZero
 * @dev     Do not use in production this is for research purposes only
 * @notice  ERC20 using LayerZero
 */

contract LzERC20Eth is OFTV2 {
    constructor(address _layerZeroEndpoint, uint256 _initialSupply, uint8 _sharedDecimals)
        OFTV2("LzERC20Eth", "lzETHEth", _sharedDecimals, _layerZeroEndpoint)
    {
        _mint(_msgSender(), _initialSupply);
    }
}
