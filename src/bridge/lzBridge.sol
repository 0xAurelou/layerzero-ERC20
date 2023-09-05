// SPDX-License-Identifier: MIT

import "openzeppelin-contracts/access/Ownable2Step.sol";
import "lz/mocks/LZEndpointMock.sol";
import "lz/token/oft/v2/IOFTV2.sol";
import "lz/token/oft/v2/ICommonOFT.sol";
import "src/bridge/ILzApp.sol";

pragma solidity 0.8.19;

/**
 * @author  0xAurelou
 * @title   Bridging Asset from different chain using LayerZero
 * @dev     Do not use in production this is for research purposes only
 * @notice  Bridge using LayerZero contract
 */
contract lzBridge is Ownable2Step {
    mapping(address => bool) public trustedToken;
    mapping(address => address) public srcTokenToDstToken;
    mapping(address => address) public srcEndpointToDstEndpoint;
    mapping(uint8 => LZEndpointMock) public lzEndpointFromChainId;

    error NullAddress();
    error InvalidToken();
    error IncorrectFees();

    constructor(address newOwner) {
        if (newOwner == address(0)) revert NullAddress();
        _transferOwnership(newOwner);
    }

    function changeLzEnpointSrc(uint8 chainId, address _lzEndpointSrc) external onlyOwner {
        lzEndpointFromChainId[chainId] = LZEndpointMock(_lzEndpointSrc);
    }

    function changeLzEnpointDst(uint8 chainId, address _lzEndpointDst) external onlyOwner {
        lzEndpointFromChainId[chainId] = LZEndpointMock(_lzEndpointDst);
    }

    function setDestLzEndpoint(
        address lzEndpointSrc,
        address lzEndpointDst,
        address tokenSrc,
        address tokenDst
    ) external onlyOwner {
        if (lzEndpointSrc == address(0)) revert NullAddress();
        if (lzEndpointDst == address(0)) revert NullAddress();
        if (tokenSrc == address(0)) revert NullAddress();
        if (tokenDst == address(0)) revert NullAddress();
        LZEndpointMock(lzEndpointSrc).setDestLzEndpoint(tokenDst, lzEndpointDst);
        LZEndpointMock(lzEndpointDst).setDestLzEndpoint(tokenSrc, lzEndpointSrc);
    }

    function setTrustedRemote(address token, uint8 chainId, bytes memory path) external onlyOwner {
        if (!trustedToken[token]) revert NullAddress();
        if (chainId == 0) revert NullAddress();
        if (path.length == 0) revert NullAddress();
        ILzApp(token).setTrustedRemote(chainId, path);
    }

    // Approval to the lzEndpointSrc should have been done before the call to this function
    function bridgeToken(uint8 dstChain, address recipient, address tokenSrc, uint256 amount)
        external
    {
        if (dstChain == 0) revert NullAddress();
        if (recipient == address(0)) revert NullAddress();
        if (!trustedToken[tokenSrc]) revert InvalidToken();

        bytes32 recipientBytes = bytes32(uint256(uint160(recipient)));

        // We estimate fees
        (uint256 fees,) =
            ICommonOFT(tokenSrc).estimateSendFee(dstChain, recipientBytes, amount, false, "");

        if (fees == 0) revert IncorrectFees();

        // callData paramater
        ICommonOFT.LzCallParams memory callParams =
            ICommonOFT.LzCallParams(payable(msg.sender), address(0), "");

        // We send 10 lzERC20Eth to the Arbitrum chain
        IOFTV2(tokenSrc).sendFrom{value: 1 ether}(
            msg.sender, dstChain, recipientBytes, amount, callParams
        );
    }
}
