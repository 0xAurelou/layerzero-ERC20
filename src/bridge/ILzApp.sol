// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ILzApp {
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external;
}
