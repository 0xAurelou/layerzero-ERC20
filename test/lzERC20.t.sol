// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/lzERC20Eth.sol";
import "src/lzERC20Arb.sol";
import "lz/mocks/LZEndpointMock.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

import "lz/token/oft/v2/ICommonOFT.sol";

contract lzERC20Test is Test {
    uint16 chainIdEth = 1;
    uint16 chainIdArb = 42_161;
    LZEndpointMock lzEndpointEth;
    LZEndpointMock lzEndpointArb;
    LzERC20Eth lzERC20Eth;
    LzERC20Arb lzERC20Arb;
    address aliceEth = address(0x10);
    address bobArb = address(0x11);

    function setUp() public {
        vm.startPrank(aliceEth);

        // Creation of Ethereum LzEndpointMock
        lzEndpointEth = new LZEndpointMock(chainIdEth);

        // Creation of Arbitrum LzEndpointMock
        lzEndpointArb = new LZEndpointMock(chainIdArb);

        // Creation of Ethereum Lz token
        lzERC20Eth = new LzERC20Eth(address(lzEndpointEth), 1000e18, 18);

        // Creation of Arbitrum Lz token
        lzERC20Arb = new LzERC20Arb(address(lzEndpointArb), 0, 18);

        // Set the LzEndpointMock destination chain
        lzEndpointEth.setDestLzEndpoint(address(lzERC20Arb), address(lzEndpointArb));

        // Set the LzEndpointMock destination chain
        lzEndpointArb.setDestLzEndpoint(address(lzERC20Eth), address(lzEndpointEth));

        // We give alice 1 ether for the gas fees
        vm.deal(aliceEth, 1 ether);

        vm.prank(aliceEth);

        // We set the trustedRemote
        lzERC20Eth.setTrustedRemote(chainIdArb, abi.encodePacked(lzERC20Arb, lzERC20Eth));

        vm.prank(aliceEth);

        // We set the trustedRemote
        lzERC20Arb.setTrustedRemote(chainIdEth, abi.encodePacked(lzERC20Eth, lzERC20Arb));
    }

    function testSetup() public {
        assertEq(lzEndpointEth.getChainId(), chainIdEth);
        assertEq(lzEndpointArb.getChainId(), chainIdArb);
        assertEq(lzERC20Eth.totalSupply(), 1000e18);
        assertEq(lzERC20Eth.balanceOf(aliceEth), 1000e18);
        assertEq(lzERC20Arb.balanceOf(bobArb), 0);
    }

    function testTransferEthereumToArbitrum() public {
        uint256 fees = 0;

        // We estimate fees
        (fees,) = lzERC20Eth.estimateSendFee(
            chainIdArb, bytes32(uint256(uint160(bobArb))), 10e18, false, ""
        );

        // Check if the fees computation have been done correctly
        assertTrue(fees != 0);

        vm.prank(aliceEth);
        lzERC20Eth.approve(address(lzEndpointEth), 1e18);

        // callData paramater
        ICommonOFT.LzCallParams memory callParams =
            ICommonOFT.LzCallParams(payable(aliceEth), address(0), "");

        // convert bobAddress to bytes32
        bytes memory bobBytes = abi.encodePacked(uint256(uint160(bobArb)));

        vm.prank(aliceEth);
        // We send 10 lzERC20Eth to the Arbitrum chain
        lzERC20Eth.sendFrom{value: 1 ether}(
            aliceEth, chainIdArb, bytes32(bobBytes), 10e18, callParams
        );

        assertEq(lzERC20Eth.balanceOf(aliceEth), 990e18);
        assertEq(lzERC20Arb.balanceOf(bobArb), 10e18);
    }
}
