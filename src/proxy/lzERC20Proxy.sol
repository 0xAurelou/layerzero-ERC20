// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ProxyOFTV2} from "lz/token/oft/v2/ProxyOFTV2.sol";

/**
 * @author  0xAurelou
 * @title   ERC20 LayerZero
 * @dev     Do not use in production this is for research purposes only
 * @notice  ERC20 using LayerZero
 */
contract LzERC20Proxy is ProxyOFTV2 {
    constructor(address _token, uint8 _sharedDecimals, address _lzEndpoint)
        ProxyOFTV2(_token, _sharedDecimals, _lzEndpoint)
    {}
}
