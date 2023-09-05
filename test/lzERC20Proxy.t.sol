// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/proxy/lzERC20Proxy.sol";
import "src/token/lzERC20Arb.sol";
import "lz/mocks/LZEndpointMock.sol";
import "src/token/lzERC20.sol";

import "lz/token/oft/v2/ICommonOFT.sol";

contract lzERC20Test is Test {
    uint16 chainIdEth = 1;
    uint16 chainIdArb = 42_161;
    LZEndpointMock lzEndpointEth;
    LZEndpointMock lzEndpointArb;
    LzERC20Proxy lzERC20Proxy;
    LzERC20 token;
    LzERC20Arb lzERC20Arb;
    address aliceEth = address(0x10);
    address bobArb = address(0x11);

    function setUp() public {
        vm.startPrank(aliceEth);

        // Creation of Ethereum LzEndpointMock
        lzEndpointEth = new LZEndpointMock(chainIdEth);

        // Creation of Arbitrum LzEndpointMock
        lzEndpointArb = new LZEndpointMock(chainIdArb);

        token = new LzERC20("Test Token", "TST", 1000e18);

        // Creation of Ethereum Lz token proxy
        lzERC20Proxy = new LzERC20Proxy(address(token), 18, address(lzEndpointEth));

        // Creation of Arbitrum Lz token
        lzERC20Arb = new LzERC20Arb(address(lzEndpointArb), 0, 18);

        // Set the LzEndpointMock destination chain
        lzEndpointEth.setDestLzEndpoint(address(lzERC20Arb), address(lzEndpointArb));

        // Set the LzEndpointMock destination chain
        lzEndpointArb.setDestLzEndpoint(address(lzERC20Proxy), address(lzEndpointEth));

        // We give alice 1 ether for the gas fees
        vm.deal(aliceEth, 1 ether);

        vm.prank(aliceEth);

        // We set the trustedRemote
        lzERC20Proxy.setTrustedRemote(chainIdArb, abi.encodePacked(lzERC20Arb, lzERC20Proxy));

        vm.prank(aliceEth);

        // We set the trustedRemote
        lzERC20Arb.setTrustedRemote(chainIdEth, abi.encodePacked(lzERC20Proxy, lzERC20Arb));
    }

    function testSetupProxy() public {
        assertEq(lzEndpointEth.getChainId(), chainIdEth);
        assertEq(lzEndpointArb.getChainId(), chainIdArb);
        assertEq(token.totalSupply(), 1000e18);
        assertEq(token.balanceOf(aliceEth), 1000e18);
        assertEq(lzERC20Arb.balanceOf(bobArb), 0);
    }

    function testTransferEthereumToArbitrumProxy() public {
        uint256 fees = 0;

        // We estimate fees
        (fees,) = lzERC20Proxy.estimateSendFee(
            chainIdArb, bytes32(uint256(uint160(bobArb))), 10e18, false, ""
        );

        // Check if the fees computation have been done correctly
        assertTrue(fees != 0);

        vm.prank(aliceEth);
        token.approve(address(lzERC20Proxy), 10e18);

        // callData paramater
        ICommonOFT.LzCallParams memory callParams =
            ICommonOFT.LzCallParams(payable(aliceEth), address(0), "");

        // convert bobAddress to bytes32
        bytes memory bobBytes = abi.encodePacked(uint256(uint160(bobArb)));

        vm.prank(aliceEth);
        // We send 10 lzERC20Proxy to the Arbitrum chain
        lzERC20Proxy.sendFrom{value: 1 ether}(
            aliceEth, chainIdArb, bytes32(bobBytes), 10e18, callParams
        );

        assertEq(token.balanceOf(aliceEth), 990e18);
        assertEq(lzERC20Arb.balanceOf(bobArb), 10e18);
    }
}
